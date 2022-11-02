require_relative "../errors"
require_relative "../serializers"
require_relative "../utils"

# This module provides the common functionality for any controller mixins, a `root` action, and
# the ability to route arbitrary actions with `extra_actions`. This is also where `api_response`
# is defined.
module RESTFramework::BaseControllerMixin
  # Default action for API root.
  def root
    api_response({message: "This is the root of your awesome API!"})
  end

  module ClassMethods
    # Helper to get the actions that should be skipped.
    def get_skip_actions(skip_undefined: true)
      # First, skip explicitly skipped actions.
      skip = self.skip_actions || []

      # Now add methods which don't exist, since we don't want to route those.
      if skip_undefined
        [:index, :new, :create, :show, :edit, :update, :destroy].each do |a|
          skip << a unless self.method_defined?(a)
        end
      end

      return skip
    end
  end

  def self.included(base)
    if base.is_a?(Class)
      base.extend(ClassMethods)

      # Add class attributes (with defaults) unless they already exist.
      {
        filter_pk_from_request_body: true,
        exclude_body_fields: [:created_at, :created_by, :updated_at, :updated_by],
        accept_generic_params_as_body_params: true,
        extra_actions: nil,
        extra_member_actions: nil,
        filter_backends: nil,
        paginator_class: nil,
        page_size: 20,
        page_query_param: "page",
        page_size_query_param: "page_size",
        max_page_size: nil,
        rescue_unknown_format_with: :json,
        serializer_class: nil,
        serialize_to_json: true,
        serialize_to_xml: true,
        singleton_controller: nil,
        skip_actions: nil,

        # Helper to disable serializer adapters by default, mainly introduced because Active Model
        # Serializers will do things like serialize `[]` into `{"":[]}`.
        disable_adapters_by_default: true,
      }.each do |a, default|
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

      # Skip csrf since this is an API.
      begin
        base.skip_before_action(:verify_authenticity_token)
      rescue
        nil
      end

      # Handle some common exceptions.
      base.rescue_from(ActiveRecord::RecordNotFound, with: :record_not_found)
      base.rescue_from(ActiveRecord::RecordInvalid, with: :record_invalid)
      base.rescue_from(ActiveRecord::RecordNotSaved, with: :record_not_saved)
      base.rescue_from(ActiveRecord::RecordNotDestroyed, with: :record_not_destroyed)
    end
  end

  # Helper to get the configured serializer class.
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

  # Helper to get filtering backends, defaulting to no backends.
  def get_filter_backends
    return self.class.filter_backends || []
  end

  # Helper to filter an arbitrary data set over all configured filter backends.
  def get_filtered_data(data)
    self.get_filter_backends.each do |filter_class|
      filter = filter_class.new(controller: self)
      data = filter.get_filtered_data(data)
    end

    return data
  end

  def record_invalid(e)
    return api_response(
      {message: "Record invalid.", exception: e, errors: e.record&.errors}, status: 400
    )
  end

  def record_not_found(e)
    return api_response({message: "Record not found.", exception: e}, status: 404)
  end

  def record_not_saved(e)
    return api_response(
      {message: "Record not saved.", exception: e, errors: e.record&.errors}, status: 406
    )
  end

  def record_not_destroyed(e)
    return api_response(
      {message: "Record not destroyed.", exception: e, errors: e.record&.errors}, status: 406
    )
  end

  # Helper to render a browsable API for `html` format, along with basic `json`/`xml` formats, and
  # with support or passing custom `kwargs` to the underlying `render` calls.
  def api_response(payload, html_kwargs: nil, **kwargs)
    html_kwargs ||= {}
    json_kwargs = kwargs.delete(:json_kwargs) || {}
    xml_kwargs = kwargs.delete(:xml_kwargs) || {}

    # Do not use any adapters by default, if configured.
    if self.class.disable_adapters_by_default && !kwargs.key?(:adapter)
      kwargs[:adapter] = nil
    end

    # Raise helpful error if payload is nil. Usually this happens when a record is not found (e.g.,
    # when passing something like `User.find_by(id: some_id)` to `api_response`). The caller should
    # actually be calling `find_by!` to raise ActiveRecord::RecordNotFound and allowing the REST
    # framework to catch this error and return an appropriate error response.
    if payload.nil?
      raise RESTFramework::NilPassedToAPIResponseError
    end

    # Flag to track if we had to rescue unknown format.
    already_rescued_unknown_format = false

    begin
      respond_to do |format|
        if payload == ""
          format.json { head(:no_content) } if self.class.serialize_to_json
          format.xml { head(:no_content) } if self.class.serialize_to_xml
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
          @title ||= self.controller_name.camelize
          @route_groups ||= RESTFramework::Utils.get_routes(Rails.application.routes, request)
          hkwargs = kwargs.merge(html_kwargs)
          begin
            render(**hkwargs)
          rescue ActionView::MissingTemplate  # fallback to rest_framework layout
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
end
