# This module provides the common functionality for all REST controllers. The implementation is
# split across several files under `controller/` for readability; each of those files reopens this
# module rather than defining a separate submodule.
module RESTFramework::Controller
  RRF_BASE_CONFIG = {
    extra_actions: nil,
    extra_member_actions: nil,
    singular: nil,

    # Options related to metadata and display.
    title: nil,
    description: nil,
    version: nil,
    inflect_acronyms: RESTFramework.config.inflect_acronyms,
    openapi_include_children: false,

    # Options related to models.
    model: nil,
    recordset: nil,
    excluded_actions: nil,

    # Bulk configuration.
    #
    # When `bulk` is truthy, it enables the default bulk behavior (`:default`), which is per-record
    # processing (e.g., `create` for each record). When `bulk` is set to `:raw`, it enables single
    # SQL query behavior (e.g., `insert_all` for bulk create) which skips validations/callbacks.
    bulk: false,
    bulk_partial: false,
    bulk_partial_query_param: "bulk_partial".freeze,
    bulk_allow_mode_override: false,
    bulk_mode_query_param: "bulk_mode".freeze,
    bulk_max_size: nil,
    bulk_max_raw_size: nil,

    # Configuring record fields.
    fields: nil,
    field_config: nil,
    read_only_fields: RESTFramework.config.read_only_fields,
    write_only_fields: RESTFramework.config.write_only_fields,
    hidden_fields: nil,

    # Finding records.
    find_by_fields: nil,
    find_by_query_param: "find_by".freeze,

    # What should be included/excluded from default fields.
    exclude_associations: false,

    # Handling request body parameters.
    allowed_parameters: nil,

    # Options for the default native serializer.
    native_serializer_config: nil,
    native_serializer_singular_config: nil,
    native_serializer_plural_config: nil,
    native_serializer_only_query_param: "only".freeze,
    native_serializer_except_query_param: "except".freeze,
    native_serializer_include_query_param: "include".freeze,
    native_serializer_exclude_query_param: "exclude".freeze,
    native_serializer_associations_limit: 5,
    native_serializer_associations_limit_max: 5,
    native_serializer_associations_limit_query_param: "associations_limit".freeze,
    native_serializer_include_associations_count: false,

    # Options for filtering, ordering, and searching.
    filter_backends: [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
    ].freeze,
    filter_recordset_before_find: true,
    filter_fields: nil,
    ordering_fields: nil,
    ordering_query_param: "ordering".freeze,
    ordering_no_reorder: false,
    search_fields: nil,
    search_query_param: "search".freeze,
    search_ilike: false,
    ransack_options: nil,
    ransack_query_param: "q".freeze,
    ransack_distinct: true,
    ransack_distinct_query_param: "distinct".freeze,

    # Options for association assignment.
    permit_id_assignment: true,
    permit_nested_attributes_assignment: true,

    # Option for `recordset.create` vs `Model.create` behavior.
    create_from_recordset: true,

    # Options related to serialization.
    rescue_unknown_format_with: :json,
    serializer_class: nil,
    serialize_to_json: true,
    serialize_to_xml: true,

    # Options related to pagination.
    paginator_class: nil,
    page_size: 20,
    page_query_param: "page",
    page_size_query_param: "page_size",
    max_page_size: nil,

    # Option to disable serializer adapters by default, mainly introduced because Active Model
    # Serializers will do things like serialize `[]` into `{"":[]}`.
    disable_adapters_by_default: true,

    # Custom integrations (reduces serializer performance due to method calls).
    enable_action_text: false,
    enable_active_storage: false,
  }

  # Exceptions to be rescued and handled by returning a reasonable error response.
  RRF_RESCUED_EXCEPTIONS = [
    RESTFramework::InvalidBulkParametersError,
    RESTFramework::BulkRecordErrorsError,
  ].freeze
  RRF_RESCUED_RAILS_EXCEPTIONS = [
    ActionController::ParameterMissing,
    ActionController::UnpermittedParameters,
    ActionDispatch::Http::Parameters::ParseError,
    ActiveRecord::AssociationTypeMismatch,
    ActiveRecord::NotNullViolation,
    ActiveRecord::RecordNotFound,
    ActiveRecord::RecordInvalid,
    ActiveRecord::RecordNotSaved,
    ActiveRecord::RecordNotDestroyed,
    ActiveRecord::RecordNotUnique,
    ActiveModel::UnknownAttributeError,
  ].freeze

  # Anchored regex with non-greedy content_type match to prevent over-matching on malicious input.
  RRF_BASE64_REGEX = /\Adata:([^;]*);base64,(.*)\z/m
  RRF_BASE64_TRANSLATE = ->(field, value) {
    return value unless RRF_BASE64_REGEX.match?(value)

    _, content_type, payload = value.match(RRF_BASE64_REGEX).to_a
    {
      io: StringIO.new(Base64.decode64(payload)),
      content_type: content_type,
      filename: "file_#{field}#{Rack::Mime::MIME_TYPES.invert[content_type]}",
    }
  }
  RRF_ACTIVESTORAGE_KEYS = [ :io, :content_type, :filename, :identify, :key ]

  # Default action for API root.
  def root
    render_api({ message: "This is the API root." })
  end

  module ClassMethods
    IGNORE_VALIDATORS_WITH_KEYS = [ :if, :unless ].freeze

    # By default, this is the name of the controller class, titleized and with any custom inflection
    # acronyms applied.
    def get_title
      self.title || RESTFramework::Utils.inflect(
        self.name.demodulize.chomp("Controller").titleize(keep_id_suffix: true),
        self.inflect_acronyms,
      )
    end

    # Get a label from a field/column name, titleized and inflected.
    def label_for(s)
      default_title = RESTFramework::Utils.inflect(
        s.to_s.titleize(keep_id_suffix: true), self.inflect_acronyms
      )
      self.model&.human_attribute_name(s, default: default_title) || default_title
    end

    # Define any behavior to execute at the end of controller definition.
    # :nocov:
    def rrf_finalize
      if RESTFramework.config.freeze_config
        self::RRF_BASE_CONFIG.keys.each { |k|
          v = self.send(k)
          v.freeze if v.is_a?(Hash) || v.is_a?(Array)
        }
      end

      self.setup_delegation if self.model
      # self.setup_channel if self.model
    end
    # :nocov:

    # Get the available fields. Fallback to this controller's model columns, or an empty array. This
    # should always return an array of strings.
    def get_fields(input_fields: nil)
      input_fields ||= self.fields

      # If fields is a hash, then parse it.
      if input_fields.is_a?(Hash)
        return RESTFramework::Utils.parse_fields_hash(
          input_fields,
          self.model,
          exclude_associations: self.exclude_associations,
          action_text: self.enable_action_text,
          active_storage: self.enable_active_storage,
        )
      elsif !input_fields
        # Otherwise, if fields is nil, then fallback to columns.
        return self.model ? RESTFramework::Utils.fields_for(
          self.model,
          exclude_associations: self.exclude_associations,
          action_text: self.enable_action_text,
          active_storage: self.enable_active_storage,
        ) : []
      elsif input_fields
        input_fields = input_fields.map(&:to_s)
      end

      input_fields
    end

    # Get a full field configuration, including defaults and inferred values.
    def field_configuration
      return @field_configuration if @field_configuration

      field_config = self.field_config&.with_indifferent_access || {}
      columns = self.model.columns_hash
      column_defaults = self.model.column_defaults
      reflections = self.model.reflections
      attributes = self.model._default_attributes
      readonly_attributes = self.model.readonly_attributes
      read_only_fields = self.read_only_fields&.map(&:to_s)&.to_set || Set[]
      write_only_fields = self.write_only_fields&.map(&:to_s)&.to_set || Set[]
      hidden_fields = self.hidden_fields&.map(&:to_s)&.to_set || Set[]
      rich_text_association_names = self.model.reflect_on_all_associations(:has_one)
        .collect(&:name)
        .select { |n| n.to_s.start_with?("rich_text_") }
      attachment_reflections = self.model.attachment_reflections

      @field_configuration = self.get_fields.map { |f|
        cfg = field_config[f]&.dup || {}
        cfg[:label] ||= self.label_for(f)

        # Annotate primary key.
        if self.model.primary_key == f
          cfg[:primary_key] = true

          unless cfg.key?(:read_only)
            cfg[:read_only] = true
          end
        end

        # Annotate field mutability and display properties.
        cfg[:read_only] = true if f.in?(readonly_attributes) || f.in?(read_only_fields)
        cfg[:write_only] = true if f.in?(write_only_fields)
        cfg[:hidden] = true if f.in?(hidden_fields)

        # Raise warnings on some bad combinations of properties.
        if cfg[:write_only]
          if cfg[:read_only]
            Rails.logger.warn("RRF: `#{f}` write_only conflicts with read_only.")
          end

          if cfg[:hidden]
            Rails.logger.warn("RRF: `#{f}` write_only implies hidden.")
          end

          if cfg[:hidden_from_index]
            Rails.logger.warn("RRF: `#{f}` write_only implies hidden_from_index.")
          end
        end

        # Annotate column data.
        if column = columns[f]
          cfg[:kind] = "column"
          cfg[:type] ||= column.type
          cfg[:required] = true unless column.null
        end

        # Add default values from the model's schema.
        if cfg[:default].nil? && (column_default = column_defaults[f])
          cfg[:default] = column_default
        end

        # Add metadata from the model's attributes hash.
        if attributes.key?(f) && attribute = attributes[f]
          if cfg[:default].nil? && default = attribute.value_before_type_cast
            cfg[:default] = default
          end
          cfg[:kind] ||= "attribute"

          # Get any type information from the attribute.
          if type = attribute.type
            cfg[:type] ||= type.type if type.type

            # Get enum variants.
            if type.is_a?(ActiveRecord::Enum::EnumType)
              cfg[:enum_variants] = type.send(:mapping)

              # TranslateEnum Integration:
              translate_method = "translated_#{f.pluralize}"
              if self.model.respond_to?(translate_method)
                cfg[:enum_translations] = self.model.send(translate_method)
              end
            end
          end
        end

        # Get association metadata.
        if ref = reflections[f]
          cfg[:kind] = "association"

          # Determine sub-fields for associations.
          if ref.polymorphic?
            ref_columns = {}
          else
            ref_columns = ref.klass.columns_hash
          end
          cfg[:sub_fields] ||= RESTFramework::Utils.sub_fields_for(ref)
          cfg[:sub_fields] = cfg[:sub_fields].map(&:to_s)

          # Very basic metadata about sub-fields.
          cfg[:sub_fields_metadata] = cfg[:sub_fields].map { |sf|
            v = {}

            if ref_columns[sf]
              v[:kind] = "column"
            else
              v[:kind] = "method"
            end

            next [ sf, v ]
          }.to_h.compact.presence

          # Determine if we render id/ids fields. Unfortunately, `has_one` does not provide this
          # interface.
          if self.permit_id_assignment && id_field = RESTFramework::Utils.id_field_for(f, ref)
            cfg[:id_field] = id_field
          end

          # Determine if we render nested attributes options.
          if self.permit_nested_attributes_assignment && (
            nested_opts = self.model.nested_attributes_options[f.to_sym].presence
          )
            cfg[:nested_attributes_options] = { field: "#{f}_attributes", **nested_opts }
          end

          begin
            cfg[:association_pk] = ref.active_record_primary_key
          rescue ActiveRecord::UnknownPrimaryKey
          end

          cfg[:reflection] = ref
        end

        # Determine if this is an ActionText "rich text".
        if :"rich_text_#{f}".in?(rich_text_association_names)
          cfg[:kind] = "rich_text"
        end

        # Determine if this is an ActiveStorage attachment.
        if ref = attachment_reflections[f]
          cfg[:kind] = "attachment"
          cfg[:attachment_type] = ref.macro
        end

        # Determine if this is just a method.
        if !cfg[:kind] && self.model.method_defined?(f)
          cfg[:kind] = "method"
          cfg[:read_only] = true if cfg[:read_only].nil?
        end

        # Collect validator options into a hash on their type, while also updating `required` based
        # on any presence validators.
        self.model.validators_on(f).each do |validator|
          kind = validator.kind
          options = validator.options

          # Reject validator if it includes keys like `:if` and `:unless` because those are
          # conditionally applied in a way that is not feasible to communicate via the API.
          next if IGNORE_VALIDATORS_WITH_KEYS.any? { |k| options.key?(k) }

          # Update `required` if we find a presence validator.
          cfg[:required] = true if kind == :presence

          # Resolve procs (and lambdas), and symbols for certain arguments.
          if options[:in].is_a?(Proc)
            options = options.merge(in: options[:in].call)
          elsif options[:in].is_a?(Symbol)
            options = options.merge(in: self.model.send(options[:in]))
          end

          cfg[:validators] ||= {}
          cfg[:validators][kind] ||= []
          cfg[:validators][kind] << options
        end

        next [ f, cfg ]
      }.to_h.compact.with_indifferent_access
    end

    # Only for model controllers.
    def setup_delegation
      # Delegate extra actions.
      self.extra_actions&.each do |action, config|
        next unless config.is_a?(Hash) && config.dig(:metadata, :delegate)
        next unless self.model.respond_to?(action)

        self.define_method(action) do
          if self.class.model.method(action).parameters.last&.first == :keyrest
            render_api(self.class.model.send(action, **request.query_parameters.symbolize_keys))
          else
            render_api(self.class.model.send(action))
          end
        end
      end

      # Delegate extra member actions.
      self.extra_member_actions&.each do |action, config|
        next unless config.is_a?(Hash) && config.dig(:metadata, :delegate)
        next unless self.model.method_defined?(action)

        self.define_method(action) do
          record = self.get_record

          if record.method(action).parameters.last&.first == :keyrest
            render_api(record.send(action, **request.query_parameters.symbolize_keys))
          else
            render_api(record.send(action))
          end
        end
      end
    end
  end

  def self.included(base)
    return unless base.is_a?(Class)

    base.extend(ClassMethods)

    # By default, the layout should be set to `rest_framework`.
    base.layout("rest_framework")

    # Add class attributes unless they already exist.
    RRF_BASE_CONFIG.each do |a, default|
      next if base.respond_to?(a)

      # Don't leak class attributes to the instance to avoid conflicting with action methods.
      base.class_attribute(a, default: default, instance_accessor: false)
    end

    # Alias `extra_actions` to `extra_collection_actions`.
    unless base.respond_to?(:extra_collection_actions)
      base.singleton_class.alias_method(:extra_collection_actions, :extra_actions)
      base.singleton_class.alias_method(:extra_collection_actions=, :extra_actions=)
    end

    # Skip CSRF since this is an API.
    begin
      base.skip_before_action(:verify_authenticity_token)
    rescue ArgumentError
      # The callback may not exist if forgery protection isn't enabled; this is expected.
      nil
    end

    # Handle exceptions.
    base.rescue_from(*RRF_RESCUED_EXCEPTIONS, with: :rrf_error_handler)
    base.rescue_from(*RRF_RESCUED_RAILS_EXCEPTIONS, with: :rrf_error_handler)

    # Use `TracePoint` hook to automatically call `rrf_finalize`.
    if RESTFramework.config.auto_finalize
      # :nocov:
      TracePoint.trace(:end) do |t|
        next if base != t.self

        base.rrf_finalize

        # It's important to disable the trace once we've found the end of the base class definition,
        # for performance.
        t.disable
      end
      # :nocov:
    end
  end

  def get_serializer_class
    self.class.serializer_class || RESTFramework::NativeSerializer
  end

  # Serialize the given data using the `serializer_class`.
  def serialize(data, **kwargs)
    RESTFramework::Utils.wrap_ams(self.get_serializer_class).new(
      data, controller: self, **kwargs
    ).serialize
  end

  def rrf_error_handler(e)
    status = case e
    when ActiveRecord::RecordNotFound
      404
    when RESTFramework::BulkRecordErrorsError
      422
    else
      400
    end

    render_api(
      {
        message: e.message,
        errors: e.try(:record).try(:errors),
        exception: RESTFramework.config.show_backtrace ? e.full_message : nil,
      }.compact,
      status: status,
    )
  end

  def route_groups
    @route_groups ||= RESTFramework::Utils.get_routes(Rails.application.routes, request)
  end

  # Render a browsable API for `html` format, along with basic `json`/`xml` formats, and with
  # support or passing custom `kwargs` to the underlying `render` calls.
  def render_api(payload, **kwargs)
    html_kwargs = kwargs.delete(:html_kwargs) || {}
    json_kwargs = kwargs.delete(:json_kwargs) || {}
    xml_kwargs = kwargs.delete(:xml_kwargs) || {}

    # Raise helpful error if payload is nil. Usually this happens when a record is not found (e.g.,
    # when passing something like `User.find_by(id: some_id)` to `render_api`). The caller should
    # actually be calling `find_by!` to raise ActiveRecord::RecordNotFound and allowing the REST
    # framework to catch this error and return an appropriate error response.
    if payload.nil?
      raise RESTFramework::NilPassedToRenderAPIError
    end

    # If `payload` is an `ActiveRecord::Relation` or `ActiveRecord::Base`, then serialize it.
    if payload.is_a?(ActiveRecord::Base) || payload.is_a?(ActiveRecord::Relation)
      payload = self.serialize(payload)
    end

    # Do not use any adapters by default, if configured.
    if self.class.disable_adapters_by_default && !kwargs.key?(:adapter)
      kwargs[:adapter] = nil
    end

    # Flag to track if we had to rescue unknown format.
    already_rescued_unknown_format = false

    begin
      respond_to do |format|
        if payload == ""
          format.json { head(kwargs[:status] || :no_content) } if self.class.serialize_to_json
          format.xml { head(kwargs[:status] || :no_content) } if self.class.serialize_to_xml
        else
          format.json {
            render(json: payload, **kwargs.merge(json_kwargs))
          } if self.class.serialize_to_json
          format.xml {
            render(xml: payload, **kwargs.merge(xml_kwargs))
          } if self.class.serialize_to_xml
          # TODO: possibly support more formats here if supported?
        end
        format.html {
          @payload = payload
          if payload == ""
            @json_payload = "" if self.class.serialize_to_json
            @xml_payload = "" if self.class.serialize_to_xml
          else
            @json_payload = payload.to_json if self.class.serialize_to_json
            @xml_payload = payload.to_xml if self.class.serialize_to_xml
          end
          @title ||= self.class.get_title
          @description ||= self.class.description
          self.route_groups
          begin
            render(**kwargs.merge(html_kwargs))
          rescue ActionView::MissingTemplate
            # A view is not required, so just use `html: ""`.
            render(html: "", layout: true, **kwargs.merge(html_kwargs))
          end
        }
      end
    rescue ActionController::UnknownFormat
      if !already_rescued_unknown_format && rescue_format = self.class.rescue_unknown_format_with
        request.format = rescue_format
        already_rescued_unknown_format = true
        retry
      else
        raise
      end
    end
  end

  def options
    render_api(self.openapi_document)
  end

  def get_fields
    self.class.get_fields(input_fields: self.class.fields)
  end

  # Get a hash of strong parameters for the current action.
  def get_allowed_parameters
    return @_get_allowed_parameters if defined?(@_get_allowed_parameters)

    @_get_allowed_parameters = self.class.allowed_parameters
    return @_get_allowed_parameters if @_get_allowed_parameters

    # Assemble strong parameters.
    variations = []
    hash_variations = {}
    reflections = self.class.model.reflections
    @_get_allowed_parameters = self.get_fields.map { |f|
      f = f.to_s
      config = self.class.field_configuration[f]

      # ActionText Integration:
      if self.class.enable_action_text && reflections.key?("rich_text_#{f}")
        next f
      end

      # ActiveStorage Integration: `has_one_attached`
      if self.class.enable_active_storage && reflections.key?("#{f}_attachment")
        hash_variations[f] = RRF_ACTIVESTORAGE_KEYS
        next f
      end

      # ActiveStorage Integration: `has_many_attached`
      if self.class.enable_active_storage && reflections.key?("#{f}_attachments")
        hash_variations[f] = RRF_ACTIVESTORAGE_KEYS
        next nil
      end

      if config[:reflection]
        # Add `_id`/`_ids` variations for associations.
        if id_field = config[:id_field]
          if id_field.ends_with?("_ids")
            hash_variations[id_field] = []
          else
            variations << id_field
          end
        end

        # Add `_attributes` variations for associations.
        # TODO: Consider adjusting this based on `nested_attributes_options`.
        if self.class.permit_nested_attributes_assignment
          hash_variations["#{f}_attributes"] = (
            config[:sub_fields] + [ "_destroy" ]
          )
        end

        # Associations are not allowed to be submitted in their bare form (if they are submitted
        # that way, they will be translated to either id/ids or nested attributes assignment).
        next nil
      end

      next f
    }.compact
    @_get_allowed_parameters += variations
    @_get_allowed_parameters << hash_variations

    @_get_allowed_parameters
  end

  # Use strong parameters to filter the request body.
  def get_body_params(bulk_action: nil)
    data = self.request.request_parameters
    pk = self.class.model&.primary_key
    allowed_params = self.get_allowed_parameters

    # Before we filter the data, dynamically dispatch association assignment to either the id/ids
    # assignment ActiveRecord API or the nested assignment ActiveRecord API. Note that there is no
    # need to check for `permit_id_assignment` or `permit_nested_attributes_assignment` here, since
    # that is enforced by strong parameters generated by `get_allowed_parameters`.
    if !bulk_action && self.class.model
      self.class.model.reflections.each do |name, ref|
        if payload = data[name]
          if payload.is_a?(Hash) || (payload.is_a?(Array) && payload.all? { |x| x.is_a?(Hash) })
            # Assume nested attributes assignment.
            attributes_key = "#{name}_attributes"
            data[attributes_key] = data.delete(name) unless data[attributes_key]
          elsif id_field = RESTFramework::Utils.id_field_for(name, ref)
            # Assume id/ids assignment.
            data[id_field] = data.delete(name) unless data[id_field]
          end
        end
      end
    end

    # ActiveStorage Integration: Translate base64 encoded attachments to upload objects.
    #
    # rubocop:disable Layout/LineLength
    #
    # Example base64 images (red, green, and blue squares):
    #   data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC
    #   data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9Qz0AEYBxVSF+FAAhKDveksOjmAAAAAElFTkSuQmCC
    #   data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNkYPhfz0AEYBxVSF+FAP5FDvcfRYWgAAAAAElFTkSuQmCC
    #
    # rubocop:enable Layout/LineLength
    has_many_attached_scalar_data = {}
    if !bulk_action && self.class.enable_active_storage && self.class.model
      self.class.model.attachment_reflections.keys.each do |k|
        if data[k].is_a?(Array)
          data[k] = data[k].map { |v|
            if v.is_a?(String)
              v = RRF_BASE64_TRANSLATE.call(k, v)

              # Remember scalars because Rails strong params will remove it.
              if v.is_a?(String)
                has_many_attached_scalar_data[k] ||= []
                has_many_attached_scalar_data[k] << v
              end
            elsif v.is_a?(Hash)
              if v[:io].is_a?(String)
                v[:io] = StringIO.new(Base64.decode64(v[:io]))
              end
            end

            next v
          }
        elsif data[k].is_a?(Hash)
          if data[k][:io].is_a?(String)
            data[k][:io] = StringIO.new(Base64.decode64(data[k][:io]))
          end
        elsif data[k].is_a?(String)
          data[k] = RRF_BASE64_TRANSLATE.call(k, data[k])
        end
      end
    end

    # Filter the request body with strong params. If `bulk` is true, then we apply allowed
    # parameters to the `_json` key of the request body.
    body_params = if allowed_params == true
      ActionController::Parameters.new(data).permit!
    elsif bulk_action
      if bulk_action == :create
        ActionController::Parameters.new(data).permit({ _json: allowed_params })
      elsif bulk_action == :update
        ActionController::Parameters.new(data).permit({ _json: allowed_params + [ pk ] })
      elsif bulk_action == :destroy
        ActionController::Parameters.new(data).permit({ _json: [] })
      else
        raise ArgumentError, "Invalid bulk action: #{bulk_action}"
      end
    else
      ActionController::Parameters.new(data).permit(*allowed_params)
    end

    # ActiveStorage Integration: Workaround for Rails strong params not allowing you to permit an
    # array containing a mix of scalars and hashes. This is needed for `has_many_attached`, because
    # API consumers must be able to provide scalar `signed_id` values for existing attachments along
    # with hashes for new attachments. It's worth mentioning that base64 scalars are converted to
    # hashes that conform to the ActiveStorage API.
    has_many_attached_scalar_data.each do |k, v|
      body_params[k].unshift(*v)
    end

    # Filter read-only fields.
    body_params.delete_if do |f, _|
      cfg = self.class.field_configuration[f]
      cfg && cfg[:read_only]
    end

    body_params
  end
  alias_method :get_create_params, :get_body_params
  alias_method :get_update_params, :get_body_params
  alias_method :get_destroy_params, :get_body_params

  # Get the set of records this controller has access to.
  def get_recordset
    return self.class.recordset if self.class.recordset

    # If there is a model, return that model's default scope (all records by default).
    if self.class.model
      return self.class.model.all
    end

    nil
  end

  # Filter the recordset and return records this request has access to.
  def get_records
    data = self.get_recordset

    @records ||= self.class.filter_backends&.reduce(data) { |d, filter|
      filter.new(controller: self).filter_data(d)
    } || data
  end

  # Get a single record by primary key or another column, if allowed.
  def get_record
    return @record if @record

    find_by_key = self.class.model.primary_key
    is_pk = true

    # Find by another column if it's permitted.
    if find_by_param = self.class.find_by_query_param.presence
      if find_by = request.query_parameters[find_by_param].presence
        find_by_fields = self.class.find_by_fields&.map(&:to_s) || self.get_fields

        if find_by.in?(find_by_fields)
          is_pk = false unless find_by_key == find_by
          find_by_key = find_by
        end
      end
    end

    # Get the recordset, filtering if configured.
    collection = if self.class.filter_recordset_before_find
      self.get_records
    else
      self.get_recordset
    end

    # Return the record. Route key is always `:id` by Rails' convention.
    if is_pk
      @record = collection.find(request.path_parameters[:id])
    else
      @record = collection.find_by!(find_by_key => request.path_parameters[:id])
    end
  end

  # Determine what collection to call `create` on.
  def create_from
    if self.class.create_from_recordset
      # Create with any properties inherited from the recordset. We exclude any `select` clauses
      # in case model callbacks need to call `count` on this collection, which typically raises a
      # SQL `SyntaxError`.
      self.get_recordset.except(:select)
    else
      # Otherwise, perform a "bare" insert_all.
      self.class.model
    end
  end
end

require_relative "controller/bulk"
require_relative "controller/crud"
require_relative "controller/openapi"
