require_relative '../errors'
require_relative '../serializers'


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
    if base.is_a? Class
      base.extend ClassMethods

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
        page_query_param: 'page',
        page_size_query_param: 'page_size',
        max_page_size: nil,
        serializer_class: nil,
        serialize_to_json: true,
        serialize_to_xml: true,
        singleton_controller: nil,
        skip_actions: nil,
      }.each do |a, default|
        unless base.respond_to?(a)
          base.class_attribute(a)

          # Set default manually so we can still support Rails 4. Maybe later we can use the default
          # parameter on `class_attribute`.
          base.send(:"#{a}=", default)
        end
      end

      # Alias `extra_actions` to `extra_collection_actions`.
      unless base.respond_to?(:extra_collection_actions)
        base.alias_method(:extra_collection_actions, :extra_actions)
        base.alias_method(:extra_collection_actions=, :extra_actions=)
      end

      # Skip csrf since this is an API.
      base.skip_before_action(:verify_authenticity_token) rescue nil

      # Handle some common exceptions.
      base.rescue_from(ActiveRecord::RecordNotFound, with: :record_not_found)
      base.rescue_from(ActiveRecord::RecordInvalid, with: :record_invalid)
      base.rescue_from(ActiveRecord::RecordNotSaved, with: :record_not_saved)
      base.rescue_from(ActiveRecord::RecordNotDestroyed, with: :record_not_destroyed)
    end
  end

  protected

  # Helper to get the configured serializer class.
  def get_serializer_class
    return self.class.serializer_class
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
    return api_response({
      message: "Record invalid.", exception: e, errors: e.record&.errors
    }, status: 400)
  end

  def record_not_found(e)
    return api_response({message: "Record not found.", exception: e}, status: 404)
  end

  def record_not_saved(e)
    return api_response({
      message: "Record not saved.", exception: e, errors: e.record&.errors
    }, status: 406)
  end

  def record_not_destroyed(e)
    return api_response({
      message: "Record not destroyed.", exception: e, errors: e.record&.errors
    }, status: 406)
  end

  # Helper for showing routes under a controller action, used for the browsable API.
  def _get_routes
    begin
      formatter = ActionDispatch::Routing::ConsoleFormatter::Sheet
    rescue NameError
      # :nocov:
      formatter = ActionDispatch::Routing::ConsoleFormatter
      # :nocov:
    end
    return ActionDispatch::Routing::RoutesInspector.new(Rails.application.routes.routes).format(
      formatter.new
    ).lines.drop(1).map { |r| r.split.last(3) }.map { |r|
      {verb: r[0], path: r[1], action: r[2]}
    }.select { |r| r[:path].start_with?(request.path) }
  end

  # Helper to render a browsable API for `html` format, along with basic `json`/`xml` formats, and
  # with support or passing custom `kwargs` to the underlying `render` calls.
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

    respond_to do |format|
      if payload == ''
        format.json {head :no_content} if self.serialize_to_json
        format.xml {head :no_content} if self.serialize_to_xml
      else
        format.json {
          jkwargs = kwargs.merge(json_kwargs)
          render(json: payload, layout: false, **jkwargs)
        } if self.serialize_to_json
        format.xml {
          xkwargs = kwargs.merge(xml_kwargs)
          render(xml: payload, layout: false, **xkwargs)
        } if self.serialize_to_xml
        # TODO: possibly support more formats here if supported?
      end
      format.html {
        @payload = payload
        if payload == ''
          @json_payload = '' if self.serialize_to_json
          @xml_payload = '' if self.serialize_to_xml
        else
          @json_payload = payload.to_json if self.serialize_to_json
          @xml_payload = payload.to_xml if self.serialize_to_xml
        end
        @template_logo_text ||= "Rails REST Framework"
        @title ||= self.controller_name.camelize
        @routes ||= self._get_routes
        hkwargs = kwargs.merge(html_kwargs)
        begin
          render(**hkwargs)
        rescue ActionView::MissingTemplate  # fallback to rest_framework layout
          hkwargs[:layout] = "rest_framework"
          hkwargs[:html] = ''
          render(**hkwargs)
        end
      }
    end
  end
end
