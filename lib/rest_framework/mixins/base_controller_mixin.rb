# This module provides the common functionality for any controller mixins, a `root` action, and
# the ability to route arbitrary actions with `extra_actions`. This is also where `render_api` is
# implemented.
module RESTFramework::Mixins::BaseControllerMixin
  RRF_BASE_CONFIG = {
    extra_actions: nil,
    extra_member_actions: nil,
    singleton_controller: nil,

    # Options related to metadata and display.
    title: nil,
    description: nil,
    version: nil,
    inflect_acronyms: ["ID", "IDs", "REST", "API", "APIs"].freeze,
    openapi_include_children: false,

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

  # Default action for API root.
  def root
    render_api({message: "This is the API root."})
  end

  module ClassMethods
    # By default, this is the name of the controller class, titleized and with any custom inflection
    # acronyms applied.
    def get_title
      return self.title || RESTFramework::Utils.inflect(
        self.name.demodulize.chomp("Controller").titleize(keep_id_suffix: true),
        self.inflect_acronyms,
      )
    end

    # Get a label from a field/column name, titleized and inflected.
    def label_for(s)
      return RESTFramework::Utils.inflect(
        s.to_s.titleize(keep_id_suffix: true),
        self.inflect_acronyms,
      )
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
    end
    # :nocov:

    def openapi_response_content_types
      return @openapi_response_content_types ||= [
        "text/html",
        self.serialize_to_json ? "application/json" : nil,
        self.serialize_to_xml ? "application/xml" : nil,
      ].compact
    end

    def openapi_request_content_types
      return @openapi_request_content_types ||= [
        "application/json",
        "application/x-www-form-urlencoded",
        "multipart/form-data",
      ]
    end

    def openapi_paths(routes, tag)
      resp_cts = self.openapi_response_content_types
      req_cts = self.openapi_request_content_types

      return routes.group_by { |r| r[:concat_path] }.map { |concat_path, routes|
        [
          concat_path.gsub(/:([0-9A-Za-z_-]+)/, "{\\1}"),
          routes.map { |route|
            metadata = RESTFramework::ROUTE_METADATA[route[:path]] || {}
            summary = metadata.delete(:label).presence || self.label_for(route[:action])
            description = metadata.delete(:description).presence
            extra_action = RESTFramework::EXTRA_ACTION_ROUTES.include?(route[:path])
            error_response = {"$ref" => "#/components/responses/BadRequest"}
            not_found_response = {"$ref" => "#/components/responses/NotFound"}
            spec = {tags: [tag], summary: summary, description: description}.compact

            # All routes should have a successful response.
            spec[:responses] = {
              200 => {content: resp_cts.map { |ct| [ct, {}] }.to_h, description: "Success"},
            }

            # Builtin POST, PUT, PATCH, and DELETE should have a 400 and 404 response.
            if route[:verb].in?(["POST", "PUT", "PATCH", "DELETE"]) && !extra_action
              spec[:responses][400] = error_response
              spec[:responses][404] = not_found_response
            end

            # All POST, PUT, PATCH should have a request body.
            if route[:verb].in?(["POST", "PUT", "PATCH"])
              spec[:requestBody] ||= {
                content: req_cts.map { |ct|
                  [ct, {}]
                }.to_h,
              }
            end

            # Add remaining metadata as an extension.
            spec["x-rrf-metadata"] = metadata if metadata.present?

            next route[:verb].downcase, spec
          }.to_h.merge(
            {
              parameters: routes.first[:route].required_parts.map { |p|
                {
                  name: p,
                  in: "path",
                  required: true,
                  schema: {type: "integer"},
                }
              },
            },
          ),
        ]
      }.to_h
    end

    def openapi_document(request, route_group_name, routes)
      server = request.base_url + request.original_fullpath.gsub(/\?.*/, "")

      return {
        openapi: "3.1.1",
        info: {
          title: self.get_title,
          description: self.description,
          version: self.version.to_s,
        }.compact,
        servers: [{url: server}],
        paths: self.openapi_paths(routes, route_group_name),
        tags: [{name: route_group_name, description: self.description}.compact],
        components: {
          schemas: {
            "Error" => {
              type: "object",
              required: ["message"],
              properties: {
                message: {type: "string"}, errors: {type: "object"}, exception: {type: "string"}
              },
            },
          },
          responses: {
            "BadRequest": {
              description: "Bad Request",
              content: self.openapi_response_content_types.map { |ct|
                [ct, ct == "text/html" ? {} : {schema: {"$ref" => "#/components/schemas/Error"}}]
              }.to_h,
            },
            "NotFound": {
              description: "Not Found",
              content: self.openapi_response_content_types.map { |ct|
                [ct, ct == "text/html" ? {} : {schema: {"$ref" => "#/components/schemas/Error"}}]
              }.to_h,
            },
          },
        },
      }.compact
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
    rescue
      nil
    end

    # Handle some common exceptions.
    unless RESTFramework.config.disable_rescue_from
      base.rescue_from(
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
        with: :rrf_error_handler,
      )
    end

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

  def get_serializer_class
    return self.class.serializer_class
  end

  # Serialize the given data using the `serializer_class`.
  def serialize(data, **kwargs)
    return RESTFramework::Utils.wrap_ams(self.get_serializer_class).new(
      data, controller: self, **kwargs
    ).serialize
  end

  def rrf_error_handler(e)
    status = case e
    when ActiveRecord::RecordNotFound
      404
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
    return @route_groups ||= RESTFramework::Utils.get_routes(Rails.application.routes, request)
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

  # Compatibility alias for deprecated `api_response`.
  alias_method :api_response, :render_api

  def openapi_document
    first, *rest = self.route_groups.to_a
    document = self.class.openapi_document(request, *first)

    if self.class.openapi_include_children
      rest.each do |route_group_name, routes|
        controller = "#{routes.first[:route].defaults[:controller]}_controller".camelize.constantize
        child_document = controller.openapi_document(request, route_group_name, routes)

        # Merge child paths and tags into the parent document.
        document[:paths].merge!(child_document[:paths])
        document[:tags] += child_document[:tags]

        # If the child document has schemas, merge them into the parent document.
        if schemas = child_document.dig(:components, :schemas)  # rubocop:disable Style/Next
          document[:components] ||= {}
          document[:components][:schemas] ||= {}
          document[:components][:schemas].merge!(schemas)
        end
      end
    end

    return document
  end

  def options
    render_api(self.openapi_document)
  end
end

# Alias for convenience.
RESTFramework::BaseControllerMixin = RESTFramework::Mixins::BaseControllerMixin
