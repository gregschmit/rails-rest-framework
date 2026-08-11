module RESTFramework::Controller
  module ClassMethods
    def openapi_response_content_types
      @openapi_response_content_types ||= [
        "text/html",
        self.serialize_to_json ? "application/json" : nil,
        self.serialize_to_xml ? "application/xml" : nil,
      ].compact
    end

    def openapi_request_content_types
      @openapi_request_content_types ||= [
        "application/json",
        "application/x-www-form-urlencoded",
        "multipart/form-data",
      ]
    end

    def openapi_paths(routes, tag)
      resp_cts = self.openapi_response_content_types
      req_cts = self.openapi_request_content_types
      schema_name = self.openapi_schema_name if self.model

      routes.group_by { |r| r[:concat_path] }.map { |concat_path, routes|
        [
          concat_path.gsub(/:([0-9A-Za-z_-]+)/, "{\\1}"),
          routes.map { |route|
            metadata = RESTFramework::ROUTE_METADATA[route[:path]] || {}
            summary = metadata.delete(:label).presence || self.label_for(route[:action])
            description = metadata.delete(:description).presence
            extra_action = RESTFramework::EXTRA_ACTION_ROUTES.include?(route[:path])
            error_response = { "$ref" => "#/components/responses/BadRequest" }
            not_found_response = { "$ref" => "#/components/responses/NotFound" }
            spec = { tags: [ tag ], summary: summary, description: description }.compact

            # All routes should have a successful response.
            success_code = if !extra_action
              if route[:action] == "create"
                201
              elsif route[:action] == "destroy"
                204
              else
                200
              end
            else
              200
            end
            spec[:responses] = {
              success_code => {
                content: resp_cts.map { |ct|
                  [
                    ct,
                    (self.model && !extra_action && route[:verb] != "OPTIONS") ? {
                      schema: { "$ref" => "#/components/schemas/#{schema_name}" },
                    } : {},
                  ]
                }.to_h,
                description: "Success",
              },
            }

            # Builtin POST, PUT, PATCH, and DELETE should have a 400 and 404 response.
            if route[:verb].in?([ "POST", "PUT", "PATCH", "DELETE" ]) && !extra_action
              spec[:responses][400] = error_response
              spec[:responses][404] = not_found_response
            end

            # All POST, PUT, PATCH should have a request body.
            if route[:verb].in?([ "POST", "PUT", "PATCH" ])
              spec[:requestBody] ||= {
                content: req_cts.map { |ct|
                  [
                    ct,
                    (self.model && !extra_action) ? {
                      schema: { "$ref" => "#/components/schemas/#{schema_name}" },
                    } : {},
                  ]
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
                  schema: { type: "integer" },
                }
              },
            },
          ),
        ]
      }.to_h
    end

    def openapi_document(request, route_group_name, routes)
      server = request.base_url + request.original_fullpath.gsub(/\?.*/, "")

      {
        openapi: "3.1.1",
        info: {
          title: self.get_title,
          description: self.description,
          version: self.version.to_s,
        }.compact,
        servers: [ { url: server } ],
        paths: self.openapi_paths(routes, route_group_name),
        tags: [ { name: route_group_name, description: self.description }.compact ],
        components: {
          schemas: {
            "Error" => {
              type: "object",
              required: [ "message" ],
              properties: {
                message: { type: "string" },
                errors: { type: "object" },
                exception: { type: "string" },
              },
            },
          }.merge(self.model ? { self.openapi_schema_name => self.openapi_schema } : {}),
          responses: {
            "BadRequest": {
              description: "Bad Request",
              content: self.openapi_response_content_types.map { |ct|
                [
                  ct,
                  ct == "text/html" ? {} : { schema: { "$ref" => "#/components/schemas/Error" } },
                ]
              }.to_h,
            },
            "NotFound": {
              description: "Not Found",
              content: self.openapi_response_content_types.map { |ct|
                [
                  ct,
                  ct == "text/html" ? {} : { schema: { "$ref" => "#/components/schemas/Error" } },
                ]
              }.to_h,
            },
          },
        },
      }.merge(self.model ? {
        "x-rrf-primary_key" => self.model.primary_key,
        "x-rrf-callbacks" => self._process_action_callbacks.as_json,

        # While bulk update/destroy are obvious because they create new router endpoints, bulk
        # create overloads the existing collection `POST` endpoint, so we add a special key to the
        # OpenAPI metadata to indicate bulk create is supported.
        "x-rrf-bulk-create": self.bulk,
      } : {}).compact
    end

    # Only for model controllers.
    def openapi_schema
      return @openapi_schema if @openapi_schema

      field_configuration = self.field_configuration
      @openapi_schema = {
        required: field_configuration.select { |_, cfg| cfg[:required] }.keys,
        type: "object",
        properties: field_configuration.map { |f, cfg|
          v = { title: cfg[:label] }

          if cfg[:kind] == "association"
            v[:type] = cfg[:reflection].collection? ? "array" : "object"
          elsif cfg[:kind] == "rich_text"
            v[:type] = "string"
            v[:"x-rrf-rich_text"] = true
          elsif cfg[:kind] == "attachment"
            v[:type] = "string"
            v[:"x-rrf-attachment"] = cfg[:attachment_type]
          else
            v[:type] = cfg[:type]
          end

          v[:readOnly] = true if cfg[:read_only]
          v[:writeOnly] = true if cfg[:write_only]
          v[:default] = cfg[:default] if cfg.key?(:default)

          if enum_variants = cfg[:enum_variants]
            v[:enum] = enum_variants.keys
            v[:"x-rrf-enum_variants"] = enum_variants
          end

          if validators = cfg[:validators]
            v[:"x-rrf-validators"] = validators
          end

          v[:"x-rrf-kind"] = cfg[:kind] if cfg[:kind]

          if cfg[:reflection]
            ref = cfg[:reflection]

            # A polymorphic `belongs_to` has no single target class, so class-derived properties
            # (`association_primary_key`, `join_table`) raise; expose the `*_type` column instead.
            polymorphic = ref.respond_to?(:polymorphic?) && ref.polymorphic?
            v[:"x-rrf-reflection"] = {
              polymorphic: polymorphic || nil,
              class_name: ref.respond_to?(:class_name) ? ref.class_name : nil,
              foreign_key: ref.respond_to?(:foreign_key) ? ref.foreign_key : nil,
              foreign_type: polymorphic ? ref.foreign_type : nil,
              association_foreign_key: ref.respond_to?(:association_foreign_key) ?
                ref.association_foreign_key : nil,
              association_primary_key: !polymorphic && ref.respond_to?(:association_primary_key) ?
                ref.association_primary_key : nil,
              inverse_of: ref.respond_to?(:inverse_of) ? ref.inverse_of&.name : nil,
              join_table: !polymorphic && ref.respond_to?(:join_table) ? ref.join_table : nil,
            }.compact
            v[:"x-rrf-association_pk"] = cfg[:association_pk]
            v[:"x-rrf-association_fields"] = cfg[:fields]
            v[:"x-rrf-association_fields_metadata"] = cfg[:association_fields_metadata]
            v[:"x-rrf-id_field"] = cfg[:id_field]
            v[:"x-rrf-nested_attributes_options"] = cfg[:nested_attributes_options]
          end

          next [ f, v ]
        }.to_h,
      }

      @openapi_schema
    end

    # Only for model controllers.
    def openapi_schema_name
      @openapi_schema_name ||= self.name.chomp("Controller").gsub("::", ".")
    end
  end

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

    document
  end
end
