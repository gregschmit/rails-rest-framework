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
        base.class_attribute(*[
          :singleton_controller,
          :extra_actions,
          :skip_actions,
          :paginator_class,
        ])
        base.rescue_from(ActiveRecord::RecordNotFound, with: :record_not_found)
        base.rescue_from(ActiveRecord::RecordInvalid, with: :record_invalid)
        base.rescue_from(ActiveRecord::RecordNotSaved, with: :record_not_saved)
        base.rescue_from(ActiveRecord::RecordNotDestroyed, with: :record_not_destroyed)
      end
    end

    protected

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

    def _get_routes
      begin
        formatter = ActionDispatch::Routing::ConsoleFormatter::Sheet
      rescue NameError
        formatter = ActionDispatch::Routing::ConsoleFormatter
      end
      return ActionDispatch::Routing::RoutesInspector.new(Rails.application.routes.routes).format(
        formatter.new
      ).lines[1..].map { |r| r.split.last(3) }.map { |r|
        {verb: r[0], path: r[1], action: r[2]}
      }.select { |r| r[:path].start_with?(request.path) }
    end

    # Helper alias for `respond_to`/`render`. `payload` should be already serialized to Ruby
    # primitives.
    def api_response(payload=nil, html_kwargs: nil, json_kwargs: nil, xml_kwargs: nil, **kwargs)
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
          end
          render(**kwargs)
        }
      end
    end
  end

end
