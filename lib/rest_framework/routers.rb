require "action_dispatch/routing/mapper"

module ActionDispatch::Routing
  class Mapper
    # Internal interface to get the controller class from the name and current scope.
    def _get_controller_class(name, pluralize: true, fallback_reverse_pluralization: true)
      # Get class name.
      name = name.to_s.camelize  # Camelize to leave plural names plural.
      name = name.pluralize if pluralize
      if name == name.pluralize
        name_reverse = name.singularize
      else
        name_reverse = name.pluralize
      end
      name += "Controller"
      name_reverse += "Controller"

      # Get scope for the class.
      if @scope[:module]
        mod = @scope[:module].to_s.camelize.constantize
      else
        mod = Object
      end

      # Convert class name to class.
      begin
        controller = mod.const_get(name)
      rescue NameError
        if fallback_reverse_pluralization
          reraise = false

          begin
            controller = mod.const_get(name_reverse)
          rescue NameError
            reraise = true
          end

          if reraise
            raise
          end
        else
          raise
        end
      end

      controller
    end

    # Internal interface for routing extra actions.
    def _route_extra_actions(actions, &block)
      parsed_actions = RESTFramework::Utils.parse_extra_actions(actions)

      parsed_actions.each do |action, config|
        config[:methods].each do |m|
          public_send(m, config[:path], action: action, **config[:kwargs])
        end

        # Record that this route is an extra action and any metadata associated with it.
        metadata = config[:metadata]
        key = "#{@scope[:path]}/#{config[:path]}"
        RESTFramework::EXTRA_ACTION_ROUTES.add(key)
        RESTFramework::ROUTE_METADATA[key] = metadata if metadata

        yield if block_given?
      end
    end

    # Unified REST route helper. Routes are determined by the controller's configuration:
    # - If the controller has a model, CRUD actions are routed explicitly.
    # - If the controller has no model, the `root` action is routed.
    # - Extra actions and extra member actions are always routed.
    # - Bulk actions (update_all, destroy_all) are routed if `bulk` is enabled.
    # - Singular controllers route `show` at the root instead of `index`.
    def rest_route(name = nil, **kwargs, &block)
      controller = kwargs.delete(:controller) || name
      if controller.is_a?(Class)
        controller_class = controller
      else
        controller_class = self._get_controller_class(controller, pluralize: false)
      end

      # Set controller if it's not explicitly set.
      kwargs[:controller] = name unless kwargs[:controller]

      has_model = !!controller_class.model
      singular = controller_class.singular
      excluded = controller_class.excluded_actions&.map(&:to_sym)&.to_set || Set.new

      # Use `resources` (plural) for plural model controllers to get member `:id` scope; use
      # `resource` (singular) for everything else.
      resource_method = (has_model && !singular) ? :resources : :resource

      public_send(resource_method, name, only: [], **kwargs) do
        if has_model
          if singular
            # Singular model controller: all CRUD actions at root path.
            get("", action: :show) unless excluded.include?(:show)
            post("", action: :create) unless excluded.include?(:create)
            unless excluded.include?(:update)
              put("", action: :update)
              patch("", action: :update)
            end
            delete("", action: :destroy) unless excluded.include?(:destroy)

            # Extra member actions at root scope for singular resources.
            if controller_class.respond_to?(:extra_member_actions)
              self._route_extra_actions(controller_class.extra_member_actions)
            end

            # Bulk actions.
            if controller_class.bulk
              unless excluded.include?(:update_all)
                put("", action: :update_all, anchor: true)
                patch("", action: :update_all, anchor: true)
              end
              unless excluded.include?(:destroy_all)
                delete("", action: :destroy_all, anchor: true)
              end
            end

            # Extra collection actions.
            self._route_extra_actions(controller_class.extra_actions)

            # Route OPTIONS action. Anchor to prevent greedy matching in Rails 8.1+.
            options("", action: :options, anchor: true)
          else
            # Plural model controller: collection and member routes.
            collection do
              get("", action: :index) unless excluded.include?(:index)
              post("", action: :create) unless excluded.include?(:create)

              # Bulk actions.
              if controller_class.bulk
                unless excluded.include?(:update_all)
                  put("", action: :update_all, anchor: true)
                  patch("", action: :update_all, anchor: true)
                end
                unless excluded.include?(:destroy_all)
                  delete("", action: :destroy_all, anchor: true)
                end
              end

              # Extra collection actions.
              self._route_extra_actions(controller_class.extra_actions)

              # Route OPTIONS action. Anchor to prevent greedy matching in Rails 8.1+.
              options("", action: :options, anchor: true)
            end

            member do
              get("", action: :show) unless excluded.include?(:show)
              unless excluded.include?(:update)
                put("", action: :update)
                patch("", action: :update)
              end
              delete("", action: :destroy) unless excluded.include?(:destroy)

              # Extra member actions.
              if controller_class.respond_to?(:extra_member_actions)
                self._route_extra_actions(controller_class.extra_member_actions)
              end
            end
          end
        else
          # Non-model controller: route `root` action and OPTIONS.
          get("", action: :root, as: "")
          self._route_extra_actions(controller_class.extra_actions)
          options("", action: :options, anchor: true)
        end

        yield if block_given?
      end
    end

    # Route a controller's `#root` to '/' in the current scope/namespace, along with other actions.
    def rest_root(name = nil, **kwargs, &block)
      controller = kwargs.delete(:controller) || name || :root

      # Remove path if name is nil (routing to the root of current namespace).
      unless name
        kwargs[:path] = ""
      end

      rest_route(controller, **kwargs, &block)
    end
  end
end
