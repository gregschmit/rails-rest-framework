require_relative '../serializers'

module RESTFramework

  # This module provides the common functionality for any controller mixins, a `root` action, and
  # the ability to route arbitrary actions with `extra_actions`. This is also where `api_response`
  # is defined.
  module BaseControllerMixin
    # Default action for API root.
    def root
      api_response({message: "This is the root of your awesome API!"})
    end

    module ClassMethods
      def get_skip_actions(skip_undefined: true)
        # first, skip explicitly skipped actions
        skip = self.skip_actions || []

        # now add methods which don't exist, since we don't want to route those
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

        # Add class attributes which don't exist yet.
        [
          :extra_actions,
          :filter_backends,
          :native_serializer_config,
          :native_serializer_action_config,
          :paginator_class,
          :page_size,
          :page_query_param,
          :page_size_query_param,
          :max_page_size,
          :serializer_class,
          :singleton_controller,
          :skip_actions,
        ].each do |a|
          base.class_attribute a unless base.respond_to?(a)

          # Set defaults manually so we can still support Rails 4.
          base.page_size_query_param = 'page_size' if a == :page_size_query_param
          base.page_query_param = 'page' if a == :page_query_param
        end

        # skip csrf since this is an API
        base.skip_before_action(:verify_authenticity_token) rescue nil

        # handle some common exceptions
        base.rescue_from(ActiveRecord::RecordNotFound, with: :record_not_found)
        base.rescue_from(ActiveRecord::RecordInvalid, with: :record_invalid)
        base.rescue_from(ActiveRecord::RecordNotSaved, with: :record_not_saved)
        base.rescue_from(ActiveRecord::RecordNotDestroyed, with: :record_not_destroyed)
      end
    end

    protected

    # Helper to get filtering backends with a sane default.
    def get_filter_backends
      if self.class.filter_backends
        return self.class.filter_backends
      end

      # By default, return nil.
      return nil
    end

    # Filter the recordset over all configured filter backends.
    def get_filtered_data(data)
      (self.get_filter_backends || []).each do |filter_class|
        filter = filter_class.new(controller: self)
        data = filter.get_filtered_data(data)
      end

      return data
    end

    # Helper to get the configured serializer class, or `NativeModelSerializer` as a default.
    def get_serializer_class
      return self.class.serializer_class || NativeModelSerializer
    end

    # Get a native serializer config for the current action.
    def get_native_serializer_config
      action_serializer_config = self.class.native_serializer_action_config || {}
      action = self.action_name.to_sym

      # Handle case where :index action is not defined.
      if action == :index && !action_serializer_config.key?(:index)
        # Default is :show if `singleton_controller`, otherwise :list.
        action = self.class.singleton_controller ? :show : :list
      end

      return (action_serializer_config[action] if action) || self.class.native_serializer_config
    end

    def record_invalid(e)
      return api_response(
        {message: "Record invalid.", exception: e, errors: e.record.errors}, status: 400
      )
    end

    def record_not_found(e)
      return api_response({message: "Record not found.", exception: e}, status: 404)
    end

    def record_not_saved(e)
      return api_response({message: "Record not saved.", exception: e}, status: 406)
    end

    def record_not_destroyed(e)
      return api_response({message: "Record not destroyed.", exception: e}, status: 406)
    end

    # Helper for showing routes under a controller action, used for the browsable API.
    def _get_routes
      begin
        formatter = ActionDispatch::Routing::ConsoleFormatter::Sheet
      rescue NameError
        formatter = ActionDispatch::Routing::ConsoleFormatter
      end
      return ActionDispatch::Routing::RoutesInspector.new(Rails.application.routes.routes).format(
        formatter.new
      ).lines.drop(1).map { |r| r.split.last(3) }.map { |r|
        {verb: r[0], path: r[1], action: r[2]}
      }.select { |r| r[:path].start_with?(request.path) }
    end

    # Helper alias for `respond_to`/`render`. `payload` should be already serialized to Ruby
    # primitives.
    def api_response(payload, html_kwargs: nil, json_kwargs: nil, xml_kwargs: nil, **kwargs)
      html_kwargs ||= {}
      json_kwargs ||= {}
      xml_kwargs ||= {}

      # allow blank (no-content) responses
      @blank = kwargs[:blank]

      respond_to do |format|
        if @blank
          format.json {head :no_content}
          format.xml {head :no_content}
        else
          if payload.respond_to?(:to_json)
            format.json {
              kwargs = kwargs.merge(json_kwargs)
              render(json: payload, layout: false, **kwargs)
            }
          end
          if payload.respond_to?(:to_xml)
            format.xml {
              kwargs = kwargs.merge(xml_kwargs)
              render(xml: payload, layout: false, **kwargs)
            }
          end
        end
        format.html {
          @payload = payload
          @json_payload = ''
          @xml_payload = ''
          unless @blank
            @json_payload = payload.to_json if payload.respond_to?(:to_json)
            @xml_payload = payload.to_xml if payload.respond_to?(:to_xml)
          end
          @template_logo_text ||= "Rails REST Framework"
          @title ||= self.controller_name.camelize
          @routes ||= self._get_routes
          kwargs = kwargs.merge(html_kwargs)
          begin
            render(**kwargs)
          rescue ActionView::MissingTemplate  # fallback to rest_framework layout/view
            kwargs[:layout] = "rest_framework"
            kwargs[:template] = "rest_framework/default"
            render(**kwargs)
          end
        }
      end
    end
  end

end
