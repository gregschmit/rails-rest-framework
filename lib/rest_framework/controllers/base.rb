module RESTFramework

  # This module provides helpers for mixin `ClassMethods` submodules.
  module ClassMethodHelpers

    # This helper assists in providing reader interfaces for mixin properties.
    def _restframework_attr_reader(property, default: nil)
      method = <<~RUBY
        def #{property}
          return _restframework_try_class_level_variable_get(
            #{property.inspect},
            default: #{default.inspect},
          )
        end
      RUBY
      self.module_eval(method)
    end
  end

  # This module provides the common functionality for any controller mixins, a `root` action, and
  # the ability to route arbitrary actions with `@extra_actions`. This is also where `api_response`
  # is defined.
  module BaseControllerMixin
    # Default action for API root.
    # TODO: use api_response and show sub-routes.
    def root
      render inline: "This is the root of your awesome API!"
    end

    protected

    module ClassMethods
      extend ClassMethodHelpers

      # Interface for getting class-level instance/class variables.
      private def _restframework_try_class_level_variable_get(name, default: nil)
        begin
          v = instance_variable_get("@#{name}")
          return v unless v.nil?
        rescue NameError
        end
        begin
          v = class_variable_get("@@#{name}")
          return v unless v.nil?
        rescue NameError
        end
        return default
      end

      # Interface for registering exceptions handlers.
      # private def _restframework_register_exception_handlers
      #   rescue_from
      # end

      _restframework_attr_reader(:extra_actions, default: {})
      _restframework_attr_reader(:template_logo_text, default: 'Rails REST Framework')

      def skip_actions(skip_undefined: true)
        # first, skip explicitly skipped actions
        skip = _restframework_try_class_level_variable_get(:skip_actions, default: [])

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
      base.extend ClassMethods
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

    # Helper alias for `respond_to`/`render`, and replace nil responses with blank ones.
    def api_response(payload, html_kwargs: nil, json_kwargs: nil, **kwargs)
      html_kwargs ||= {}
      json_kwargs ||= {}

      respond_to do |format|
        format.html {
          kwargs = kwargs.merge(html_kwargs)
          @template_logo_text ||= "Rails REST Framework"
          @title ||= self.controller_name.camelize
          @routes ||= self._get_routes
          @payload = payload
          begin
            render(**kwargs)
          rescue ActionView::MissingTemplate  # fallback to rest_framework default view
            kwargs[:template] = "rest_framework/default"
          end
          render(**kwargs)
        }
        format.json {
          kwargs = kwargs.merge(json_kwargs)
          render(json: payload || '', **kwargs)
        }
      end
    end
  end

end
