require_relative "../errors"
require_relative "../serializers"
require_relative "../utils"

# This module provides the common functionality for any controller mixins, a `root` action, and
# the ability to route arbitrary actions with `extra_actions`. This is also where `api_response`
# is defined.
module RESTFramework::BaseControllerMixin
  RRF_BASE_CONTROLLER_CONFIG = {
    filter_pk_from_request_body: true,
    exclude_body_fields: [
      :created_at, :created_by, :created_by_id, :updated_at, :updated_by, :updated_by_id
    ].freeze,
    accept_generic_params_as_body_params: false,
    show_backtrace: false,
    extra_actions: nil,
    extra_member_actions: nil,
    filter_backends: nil,
    singleton_controller: nil,

    # Options related to metadata and display.
    title: nil,
    description: nil,
    inflect_acronyms: ["ID", "IDs", "REST", "API", "APIs"].freeze,

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

    # Options related to bulk actions and batch processing.
    bulk_guard_query_param: nil,
    enable_batch_processing: nil,

    # Option to disable serializer adapters by default, mainly introduced because Active Model
    # Serializers will do things like serialize `[]` into `{"":[]}`.
    disable_adapters_by_default: true,
  }

  # Default action for API root.
  def root
    api_response({message: "This is the API root."})
  end

  module ClassMethods
    # Get the title of this controller. By default, this is the name of the controller class,
    # titleized and with any custom inflection acronyms applied.
    def get_title
      return self.title || RESTFramework::Utils.inflect(
        self.name.demodulize.chomp("Controller").titleize(keep_id_suffix: true),
        self.inflect_acronyms,
      )
    end

    # Get a label from a field/column name, titleized and inflected.
    def get_label(s)
      return RESTFramework::Utils.inflect(s.titleize(keep_id_suffix: true), self.inflect_acronyms)
    end

    # Collect actions (including extra actions) metadata for this controller.
    def get_actions_metadata
      actions = {}

      # Start with builtin actions.
      RESTFramework::BUILTIN_ACTIONS.merge(
        RESTFramework::RRF_BUILTIN_ACTIONS,
      ).each do |action, methods|
        if self.method_defined?(action)
          actions[action] = {path: "", methods: methods, type: :builtin}
        end
      end

      # Add builtin bulk actions.
      RESTFramework::RRF_BUILTIN_BULK_ACTIONS.each do |action, methods|
        if self.method_defined?(action)
          actions[action] = {path: "", methods: methods, type: :builtin}
        end
      end

      # Add extra actions.
      if extra_actions = self.try(:extra_actions)
        actions.merge!(RESTFramework::Utils.parse_extra_actions(extra_actions, controller: self))
      end

      return actions
    end

    # Collect member actions (including extra member actions) metadata for this controller.
    def get_member_actions_metadata
      actions = {}

      # Start with builtin actions.
      RESTFramework::BUILTIN_MEMBER_ACTIONS.each do |action, methods|
        if self.method_defined?(action)
          actions[action] = {path: "", methods: methods, type: :builtin}
        end
      end

      # Add extra actions.
      if extra_actions = self.try(:extra_member_actions)
        actions.merge!(RESTFramework::Utils.parse_extra_actions(extra_actions, controller: self))
      end

      return actions
    end

    # Get a hash of metadata to be rendered in the `OPTIONS` response. Cache the result.
    def get_options_metadata
      return @_base_options_metadata ||= {
        title: self.get_title,
        description: self.description,
        renders: [
          "text/html",
          self.serialize_to_json ? "application/json" : nil,
          self.serialize_to_xml ? "application/xml" : nil,
        ].compact,
        actions: self.get_actions_metadata,
        member_actions: self.get_member_actions_metadata,
      }.compact
    end

    # Define any behavior to execute at the end of controller definition.
    # :nocov:
    def rrf_finalize
      if RESTFramework.config.freeze_config
        self::RRF_BASE_CONTROLLER_CONFIG.keys.each { |k|
          v = self.send(k)
          v.freeze if v.is_a?(Hash) || v.is_a?(Array)
        }
      end
    end
    # :nocov:
  end

  def self.included(base)
    return unless base.is_a?(Class)

    base.extend(ClassMethods)

    # Add class attributes (with defaults) unless they already exist.
    RRF_BASE_CONTROLLER_CONFIG.each do |a, default|
      next if base.respond_to?(a)

      base.class_attribute(a)

      # Set default manually so we can still support Rails 4. Maybe later we can use the default
      # parameter on `class_attribute`.
      base.send(:"#{a}=", default)
    end

    # Alias `extra_actions` to `extra_collection_actions`.
    unless base.respond_to?(:extra_collection_actions)
      base.alias_method(:extra_collection_actions, :extra_actions)
      base.alias_method(:extra_collection_actions=, :extra_actions=)
    end

    # Skip CSRF since this is an API.
    begin
      base.skip_before_action(:verify_authenticity_token)
    rescue
      nil
    end

    # Handle some common exceptions.
    base.rescue_from(
      ActiveRecord::RecordNotFound,
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved,
      ActiveRecord::RecordNotDestroyed,
      ActiveRecord::RecordNotUnique,
      ActiveModel::UnknownAttributeError,
      ActiveRecord::StatementInvalid,
      with: :rrf_error_handler,
    )

    # Use `TracePoint` hook to automatically call `rrf_finalize`.
    unless RESTFramework.config.disable_auto_finalize
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

  # Get the configured serializer class.
  def get_serializer_class
    return nil unless serializer_class = self.class.serializer_class

    # Support dynamically resolving serializer given a symbol or string.
    serializer_class = serializer_class.to_s if serializer_class.is_a?(Symbol)
    if serializer_class.is_a?(String)
      serializer_class = self.class.const_get(serializer_class)
    end

    # Wrap it with an adapter if it's an active_model_serializer.
    if defined?(ActiveModel::Serializer) && (serializer_class < ActiveModel::Serializer)
      serializer_class = RESTFramework::ActiveModelSerializerAdapterFactory.for(serializer_class)
    end

    return serializer_class
  end

  # Serialize the given data using the `serializer_class`.
  def serialize(data, **kwargs)
    return self.get_serializer_class.new(data, controller: self, **kwargs).serialize
  end

  # Get filtering backends, defaulting to no backends.
  def get_filter_backends
    return self.class.filter_backends || []
  end

  # Filter an arbitrary data set over all configured filter backends.
  def get_filtered_data(data)
    self.get_filter_backends.each do |filter_class|
      filter = filter_class.new(controller: self)
      data = filter.get_filtered_data(data)
    end

    return data
  end

  def get_options_metadata
    return self.class.get_options_metadata
  end

  def rrf_error_handler(e)
    status = case e
    when ActiveRecord::RecordNotFound
      404
    else
      400
    end

    return api_response(
      {
        message: e.message,
        errors: e.try(:record).try(:errors),
        exception: self.class.show_backtrace ? e.full_message : nil,
      }.compact,
      status: status,
    )
  end

  # Render a browsable API for `html` format, along with basic `json`/`xml` formats, and with
  # support or passing custom `kwargs` to the underlying `render` calls.
  def api_response(payload, html_kwargs: nil, **kwargs)
    html_kwargs ||= {}
    json_kwargs = kwargs.delete(:json_kwargs) || {}
    xml_kwargs = kwargs.delete(:xml_kwargs) || {}

    # Raise helpful error if payload is nil. Usually this happens when a record is not found (e.g.,
    # when passing something like `User.find_by(id: some_id)` to `api_response`). The caller should
    # actually be calling `find_by!` to raise ActiveRecord::RecordNotFound and allowing the REST
    # framework to catch this error and return an appropriate error response.
    if payload.nil?
      raise RESTFramework::NilPassedToAPIResponseError
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
            jkwargs = kwargs.merge(json_kwargs)
            render(json: payload, layout: false, **jkwargs)
          } if self.class.serialize_to_json
          format.xml {
            xkwargs = kwargs.merge(xml_kwargs)
            render(xml: payload, layout: false, **xkwargs)
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
          @template_logo_text ||= "Rails REST Framework"
          @title ||= self.class.get_title
          @description ||= self.class.description
          @route_props, @route_groups = RESTFramework::Utils.get_routes(
            Rails.application.routes, request
          )
          hkwargs = kwargs.merge(html_kwargs)
          begin
            render(**hkwargs)
          rescue ActionView::MissingTemplate  # Fallback to `rest_framework` layout.
            hkwargs[:layout] = "rest_framework"
            hkwargs[:html] = ""
            render(**hkwargs)
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

  # Provide a generic `OPTIONS` response with metadata such as available actions.
  def options
    return api_response(self.get_options_metadata)
  end
end
