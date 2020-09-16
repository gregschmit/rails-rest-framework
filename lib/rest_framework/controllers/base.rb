module RESTFramework

  module ClassMethodHelpers
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
      _restframework_attr_reader(:skip_actions, default: [])
    end

    def self.included(base)
      base.extend ClassMethods
    end

    # Helper alias for `respond_to`/`render`, and replace nil responses with blank ones.
    def api_response(value, **kwargs)
      respond_to do |format|
        format.html
        format.json { render json: value || '', **kwargs }
      end
    end
  end

end
