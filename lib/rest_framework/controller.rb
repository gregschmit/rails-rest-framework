# This module provides the common functionality for all REST controllers. The implementation is
# split across several files under `controller/` for readability; each of those files reopens this
# module rather than defining a separate submodule.
module RESTFramework::Controller
  RRF_BASE_CONFIG = {
    model: nil,
    singular: nil,

    # Options related to metadata and display.
    title: nil,
    description: nil,
    version: nil,
    inflect_acronyms: RESTFramework.config.inflect_acronyms,
    openapi_include_children: false,

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

    # Configuring record fields. `fields` is the single source of truth: an Array (sugar for
    # `only:`), or a Hash of `only:`/`include:`/`exclude:`/`except:` (set membership) plus `config:`
    # (per-field configuration, keyed by field name).
    fields: nil,
    read_only_fields: RESTFramework.config.read_only_fields,
    write_only_fields: RESTFramework.config.write_only_fields,
    hidden_fields: nil,

    # Finding records.
    find_by_fields: nil,
    find_by_query_param: "find_by".freeze,

    # Handling request body parameters.
    allowed_parameters: nil,

    # Query params for the default native serializer's field selection.
    only_query_param: "only".freeze,
    except_query_param: "except".freeze,
    include_query_param: "include".freeze,
    exclude_query_param: "exclude".freeze,

    # Options for including associations and collection counts.
    exclude_associations: false,
    include_association_count: false,

    # Options for association serialization.
    association_limit: 10,
    association_limit_max: 100,
    enable_association_queries: false,
    association_query_prefix: "associations".freeze,

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

    # Options related to pagination. Pagination is on by default (page-number based) with a capped
    # page size, so responses are bounded out of the box; set `paginator_class = nil` to disable.
    paginator_class: RESTFramework::PageNumberPaginator,
    page_size: 20,
    page_query_param: "page".freeze,
    page_size_query_param: "page_size".freeze,
    max_page_size: 40,
    # Whether the page-number paginator computes the total record count to report `count` and
    # `total_pages`. Set to `false` on large tables to skip that query.
    page_total_count: true,

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
    ActiveRecord::StatementInvalid,
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

  module ClassMethods
    IGNORE_VALIDATORS_WITH_KEYS = [ :if, :unless ].freeze

    # Thread-local key toggled by `propagate` while its block runs.
    RRF_PROPAGATING_KEY = :rrf_propagating

    # Define one or more class-level configuration attributes. Assignments are **local by default**:
    #
    #   self.x = value               # applies to this controller ONLY; descendants don't inherit it
    #   propagate { self.x = value } # applies to this controller AND all descendants
    #
    # This gives a single, uniform rule (an assignment is local unless wrapped in `propagate`), so
    # there's no per-attribute "does this inherit?" knowledge to carry around. Values are stored in
    # closures on redefined singleton methods (the same mechanism as `class_attribute`), never in
    # instance variables, so there is exactly one interface for configuration: the setter.
    #
    # Only singleton (class-level) methods are defined, so config never leaks to controller
    # instances (which would risk colliding with action methods).
    def rrf_class_attribute(*names, default: nil)
      names.each do |name|
        # Propagating baseline: every controller sees the default until it's overridden. This lives
        # in the propagated module (see `rrf_propagated_module`) rather than directly on the
        # singleton class, so a local assignment can coexist with it via `super`.
        rrf_propagated_module.define_method(name) { default }

        # Parity with `class_attribute`, which also defines a predicate.
        singleton_class.define_method("#{name}?") { !!public_send(name) }

        singleton_class.define_method("#{name}=") do |value|
          if Thread.current[RRF_PROPAGATING_KEY]
            # Propagate: descendants inherit this getter via the module in the singleton chain. It's
            # kept separate from any local getter (defined directly on the singleton class) so a
            # subsequent local assignment doesn't clobber the value propagated to descendants.
            rrf_propagated_module.define_method(name) { value }
          else
            # Local: `value` for this class only; descendants fall back through `super` to the
            # nearest propagated ancestor value, or the default.
            klass = self
            singleton_class.define_method(name) do
              if equal?(klass)
                value
              elsif defined?(super)
                super()
              else
                default
              end
            end
          end
        end
      end
    end

    # The per-class module holding this class's propagated attribute getters (and the default
    # baseline). It's included into the singleton class so descendants inherit propagated values
    # through the singleton-class chain, while local assignments—defined directly on the singleton
    # class—take precedence for the class itself and can `super()` back into this module. Created
    # lazily and memoized per class (instance variables aren't inherited, so each class gets its
    # own).
    def rrf_propagated_module
      @rrf_propagated_module ||= Module.new.tap { |mod| singleton_class.include(mod) }
    end

    # Run a block in which configuration setters (`self.x = value`) propagate to descendant
    # controllers instead of applying locally. Use this on a shared base controller for settings you
    # want every subclass to inherit:
    #
    #   propagate do
    #     self.paginator_class = RESTFramework::PageNumberPaginator
    #     self.page_size = 30
    #   end
    def propagate
      previous = Thread.current[RRF_PROPAGATING_KEY]
      Thread.current[RRF_PROPAGATING_KEY] = true
      yield
    ensure
      Thread.current[RRF_PROPAGATING_KEY] = previous
    end

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

    # Resolve the `fields` config to an array of strings. Memoized, since `fields` and the flags it
    # depends on are class-level config fixed at load time.
    def get_fields
      @get_fields ||= if self.fields.is_a?(Hash)
        RESTFramework::Utils.parse_fields_hash(
          self.fields,
          self.model,
          exclude_associations: self.exclude_associations,
          action_text: self.enable_action_text,
          active_storage: self.enable_active_storage,
        )
      elsif self.fields
        self.fields.map(&:to_s)
      elsif self.model
        RESTFramework::Utils.fields_for(
          self.model,
          exclude_associations: self.exclude_associations,
          action_text: self.enable_action_text,
          active_storage: self.enable_active_storage,
        )
      else
        []
      end
    end

    # Get a full field configuration, including defaults and inferred values.
    def field_configuration
      return @field_configuration if @field_configuration

      field_config = (self.fields.is_a?(Hash) ? self.fields[:config] : nil)
        &.with_indifferent_access || {}
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

        # An explicit `read_only`/`write_only` in `field_config` wins over every framework default
        # below (primary key, readonly attributes, the read/write-only config lists, and the
        # method-field default), so those only apply when the developer set neither.
        read_write_only_set = cfg.key?(:read_only) || cfg.key?(:write_only)

        # Annotate primary key.
        if self.model.primary_key == f
          cfg[:primary_key] = true
          cfg[:read_only] = true unless read_write_only_set
        end

        # Annotate field mutability and display properties.
        unless read_write_only_set
          cfg[:read_only] = true if f.in?(readonly_attributes) || f.in?(read_only_fields)
          cfg[:write_only] = true if f.in?(write_only_fields)
        end
        cfg[:hidden] = true if f.in?(hidden_fields)

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

            if type.is_a?(ActiveRecord::Enum::EnumType)
              cfg[:enum] = true
              cfg[:options] ||= type.send(:mapping).invert

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

          # Determine the association's fields.
          if ref.polymorphic?
            ref_columns = {}
          else
            ref_columns = ref.klass.columns_hash
          end
          # The association's `fields` config is itself a spec (Array or `only:`/`include:`/
          # `exclude:`/`config:` Hash). Resolve its membership to a name array (consumed by the
          # serializer, filters, and OpenAPI) and stash any nested `config:` for the serializer's
          # recursion.
          spec = RESTFramework::Utils.normalize_field_spec(cfg[:fields])
          cfg[:fields] = RESTFramework::Utils.resolve_field_names(
            spec, RESTFramework::Utils.association_fields_for(ref)
          )
          cfg[:field_config] = spec[:config] if spec[:config]

          # Strings, to match `:fields` when intersecting requested fields against the allowlist.
          if cfg[:requestable_fields]
            cfg[:requestable_fields] = cfg[:requestable_fields].map(&:to_s)
          end

          # Very basic metadata about the association's fields.
          cfg[:association_fields_metadata] = cfg[:fields].map { |sf|
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
          # Methods are read-only by default, unless the field was marked read/write-only.
          cfg[:read_only] = true unless read_write_only_set || cfg[:write_only]
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

          cfg[:validators] ||= {}
          cfg[:validators][kind] ||= []
          cfg[:validators][kind] << options
        end

        # Warn on bad combinations, once every property has been resolved.
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

        next [ f, cfg ]
      }.to_h.compact.with_indifferent_access

      # Compile each association's requestable-fields allowlist once (see
      # `enable_association_queries`). This runs as a second pass, after `@field_configuration` is
      # memoized, because resolving a sibling's fields reads its `field_configuration` — and a
      # self-referential or mutual association would otherwise recurse into this build.
      if self.enable_association_queries
        @field_configuration.each do |_f, cfg|
          next unless cfg[:kind] == "association"

          cfg[:requestable_fields] ||= self.association_requestable_fields(cfg[:reflection])
        end
      end

      @field_configuration
    end

    # The fields a consumer may request for an association beyond its defaults, derived from the
    # associated model's sibling controller: what that controller serializes, so the association can
    # never expose more than its own endpoint would. Empty unless the sibling is discoverable and
    # introspectable — a custom `serializer_class` makes its `get_fields` meaningless. Hidden fields
    # are included (retrievable via `?only=` there); write-only and nested associations aren't.
    def association_requestable_fields(ref)
      return [] if ref.polymorphic?

      sibling = RESTFramework::Utils.controller_for_model(self, ref.klass)
      return [] unless sibling
      return [] if sibling.serializer_class

      cfg = sibling.field_configuration
      sibling.get_fields.reject { |sf|
        c = cfg[sf]
        c.nil? || c[:write_only] || c[:kind] == "association"
      }
    end
  end

  def self.included(base)
    return unless base.is_a?(Class)

    base.extend(ClassMethods)

    # By default, the layout should be set to `rest_framework`.
    base.layout("rest_framework")

    # Materialize config with `rrf_class_attribute` (local by default) rather than `class_attribute`
    # (always inherited).
    RRF_BASE_CONFIG.each do |a, default|
      next if base.respond_to?(a)

      base.rrf_class_attribute(a, default: default)
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

    # `StatementInvalid` messages commonly embed SQL fragments and schema details, so don't leak
    # them to clients unless backtraces are explicitly enabled.
    message = if e.is_a?(ActiveRecord::StatementInvalid) && !RESTFramework.config.show_backtrace
      "Invalid query."
    else
      e.message
    end

    render_api(
      {
        message: message,
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
    self.class.get_fields
  end

  def readable_fields
    @_readable_fields ||= begin
      cfg = self.class.field_configuration
      self.get_fields.reject { |f| cfg[f]&.[](:write_only) }
    end
  end

  # The fields a client may write (create/update): `get_fields` minus read_only fields. Excluding
  # them here — before strong parameters expand associations into `_id`/`_ids`/`_attributes` keys —
  # keeps a read_only association from ever producing a permitted (and otherwise unstrippable, since
  # those keys don't match a field name) assignment key.
  def writable_fields
    @_writable_fields ||= begin
      cfg = self.class.field_configuration
      self.get_fields.reject { |f| cfg[f]&.[](:read_only) }
    end
  end

  # `readable_fields` restricted to real columns, for query surfaces that build SQL directly
  # (find_by, search) and would raise on a virtual/method field.
  def readable_columns
    @_readable_columns ||= self.readable_fields & self.class.model.column_names
  end

  # `readable_fields` restricted to columns and associations, for surfaces that also resolve dotted
  # `association.sub_field` paths (filtering, ordering). Excludes virtual/method fields, which have
  # no column to order or filter by.
  def readable_columns_or_associations
    @_readable_columns_or_associations ||= begin
      cfg = self.class.field_configuration
      columns = self.class.model.column_names
      self.readable_fields.select do |f|
        next true if f.in?(columns)

        # Skip polymorphic associations: they can't be JOINed, so filtering or ordering *through*
        # them (e.g. `?favorite.name=x`) would raise. Their backing `*_id`/`*_type` columns are
        # still filterable/orderable via `readable_polymorphic_columns`.
        field = cfg[f]
        field&.[](:kind) == "association" && !field[:reflection]&.polymorphic?
      end
    end
  end

  # Map each readable polymorphic `belongs_to`'s dotted `<name>.id`/`<name>.type` path to its
  # backing `*_id`/`*_type` column. These columns live on the base table, so — unlike the
  # association itself, which can't be JOINed — they filter and order like any other column. The
  # dotted path mirrors the serialized shape, so clients filter with `?favorite.type=Genre`.
  def readable_polymorphic_columns
    @_readable_polymorphic_columns ||= begin
      cfg = self.class.field_configuration
      self.readable_fields.each_with_object({}) do |f, map|
        field = cfg[f]
        next unless field&.[](:kind) == "association"

        ref = field[:reflection]
        next unless ref&.polymorphic?

        map["#{f}.id"] = ref.foreign_key
        map["#{f}.type"] = ref.foreign_type
      end
    end
  end

  # Get a hash of strong parameters for the current action.
  def get_allowed_parameters
    return @_get_allowed_parameters if defined?(@_get_allowed_parameters)

    @_get_allowed_parameters = self.class.allowed_parameters
    return @_get_allowed_parameters if @_get_allowed_parameters

    # Assemble strong parameters from writable fields only, so read-only fields never produce a
    # permitted key — including the `_id`/`_ids`/`_attributes` variations an association expands
    # into, which a later key-name-based filter couldn't catch. Bulk update re-permits the primary
    # key (see `get_body_params`) since it needs it to locate each record.
    variations = []
    hash_variations = {}
    reflections = self.class.model.reflections
    @_get_allowed_parameters = self.writable_fields.map { |f|
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

      # JSON/JSONB columns hold opaque structured data, so permit hash (and nested) values here.
      # Scalar and array values can't share this slot in strong params, so `get_body_params`
      # re-injects them after filtering.
      if config[:type].in?(%i[json jsonb])
        hash_variations[f] = {}
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
            config[:fields] + [ "_destroy" ]
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

  # Writable JSON/JSONB columns, whose values are opaque and may arrive as any JSON type.
  def get_json_columns
    return @_get_json_columns if defined?(@_get_json_columns)

    @_get_json_columns = self.writable_fields.map(&:to_s).select { |f|
      self.class.field_configuration[f]&.[](:type).in?(%i[json jsonb])
    }
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

    # JSON/JSONB columns accept any JSON value. Strong params permit a hash for such a key (via
    # `key: {}`; see `get_allowed_parameters`), but can't also accept a scalar or array in that
    # slot, so remember non-hash values now and re-inject them after filtering.
    json_scalar_or_array_data = {}
    if !bulk_action && self.class.model
      self.get_json_columns.each do |f|
        json_scalar_or_array_data[f] = data[f] if data.key?(f) && !data[f].is_a?(Hash)
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

    # Re-inject scalar/array JSON column values that strong params dropped (see above).
    json_scalar_or_array_data.each do |k, v|
      body_params[k] = v
    end

    body_params
  end
  alias_method :get_create_params, :get_body_params
  alias_method :get_update_params, :get_body_params
  alias_method :get_destroy_params, :get_body_params

  # Get the set of records this controller has access to. Override this to scope records (e.g. to
  # the current user); the default scopes to a nested parent resource when one is present in the
  # path, otherwise the model's default scope (all records).
  def get_recordset
    return nil unless self.class.model

    self._rrf_nested_parent_recordset || self.class.model.all
  end

  # For a nested route, walk the whole parent chain in path order and return the innermost
  # collection of this controller's model — e.g. `/movies/:movie_id/genres/:genre_id/tracks` becomes
  # `Movie.find(movie_id).genres.find(genre_id).tracks`. Every link is enforced (a broken one raises
  # `RecordNotFound` -> 404), and each association is resolved from its parent, so `belongs_to`,
  # `has_many`, and `has_and_belongs_to_many` children all work. Each parent is looked up via its
  # own controller's recordset, so per-level access scoping is enforced. Returns `nil` when there is
  # no nested parent, or a `<name>_id` param can't connect. Override `get_recordset` to scope
  # differently.
  def _rrf_nested_parent_recordset
    # Set on an ad-hoc parent instance below, so evaluating a parent's `get_recordset` doesn't
    # recurse back into nested scoping (we want the parent's own scope, not to re-nest it).
    return nil if @_rrf_scoping_parent
    return nil unless request

    # `<name>_id` path parameters that name a model, in route order (outermost parent first).
    parents = request.path_parameters.filter_map { |key, value|
      key = key.to_s
      next unless key.end_with?("_id")

      model = key.delete_suffix("_id").classify.safe_constantize
      next unless model.is_a?(Class) && model < ActiveRecord::Base

      [ model, value ]
    }
    return nil if parents.empty?

    # Find the outermost parent within its controller's scope, then descend: each next parent is
    # constrained both to the previous parent's association and to its own controller's scope.
    record = nil
    parents.each do |model, id|
      scope = _rrf_parent_recordset(model)

      unless record.nil?
        assoc = _rrf_collection_association_name(record.class, model)
        return nil unless assoc

        scope = record.public_send(assoc).merge(scope)
      end

      record = scope.find(id)
    end

    # Finally, the innermost parent's collection of this controller's model.
    assoc = _rrf_collection_association_name(record.class, self.class.model)
    return nil unless assoc

    record.public_send(assoc)
  end

  # A parent's recordset for the nested-scope walk: its own controller's `get_recordset` (so that
  # controller's access scoping is reused), or the bare model when no sibling controller is found.
  # The ad-hoc instance shares this request and skips its own nested scoping.
  def _rrf_parent_recordset(model)
    controller = RESTFramework::Utils.controller_for_model(self.class, model)
    return model.all unless controller

    instance = controller.new
    instance.request = request
    instance.response = response
    instance.instance_variable_set(:@_rrf_scoping_parent, true)
    instance.get_recordset
  end

  # The name of `klass`'s collection association whose records are `target_model`, or `nil`.
  def _rrf_collection_association_name(klass, target_model)
    klass.reflect_on_all_associations.find { |ref|
      ref.collection? && !ref.polymorphic? && ref.klass == target_model
    }&.name
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
        # Default to readable columns: excluding write_only keeps hidden values from being used as
        # lookup keys, and restricting to real columns keeps virtual/method fields from reaching a
        # doomed `find_by(<not a column>)` (which would raise on the DB).
        find_by_fields = self.class.find_by_fields&.map(&:to_s) || self.readable_columns

        # A `find_by` was explicitly requested, so it must be a permitted field.
        raise ActiveRecord::RecordNotFound unless find_by.in?(find_by_fields)

        is_pk = false unless find_by_key == find_by
        find_by_key = find_by
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

require_relative "controller/actions"
require_relative "controller/bulk"
require_relative "controller/crud"
require_relative "controller/openapi"
