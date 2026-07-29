require "action_dispatch/routing/mapper"

module ActionDispatch::Routing
  class Mapper
    # Resolve a controller class from a route name and the current scope. The name must match the
    # controller exactly (camelized, plus `Controller`) — there is no pluralization fallback.
    def _rrf_controller_class(name)
      mod = @scope[:module] ? @scope[:module].to_s.camelize.constantize : Object
      mod.const_get("#{name.to_s.camelize}Controller")
    end

    # Route each action from a controller's action store.
    def _rrf_route_actions(actions)
      actions.each_value do |spec|
        # Delegated actions keep their declared action name (so routing and OpenAPI show the real
        # name); `method_for_action` redirects dispatch to `rrf_delegate`, which needs the scope.
        kwargs = spec.kwargs
        if !spec.builtin && spec.metadata&.[](:delegate)
          kwargs = kwargs.merge(rrf_delegate_scope: spec.type)
        end

        spec.methods.each do |m|
          public_send(m, spec.path, action: spec.name, **kwargs)
        end

        # Record non-builtin (extra) actions and their metadata for the browsable API / OpenAPI.
        next if spec.builtin

        key = "#{@scope[:path]}/#{spec.path}"
        RESTFramework::EXTRA_ACTION_ROUTES.add(key)
        RESTFramework::ROUTE_METADATA[key] = spec.metadata if spec.metadata
      end
    end

    # Route one or more controllers from their action stores. Plural model controllers get
    # collection/member scopes; singular and non-model controllers route everything at the root.
    # Passing several names condenses simple routes into one call; per-name options (`path:`, `as:`,
    # `controller:`, and a block) only apply to a single name.
    def rest_route(*names, **kwargs, &block)
      if names.size > 1 && (block || (kwargs.keys & [ :path, :as, :controller ]).any?)
        raise ArgumentError, "rest_route: options and a block require a single name"
      end

      names.each { |name| _rrf_rest_route(name, **kwargs, &block) }
    end

    # Route a single controller from its action store.
    def _rrf_rest_route(name, **kwargs)
      controller = kwargs.delete(:controller) || name
      if controller.is_a?(Class)
        controller_class = controller
      else
        controller_class = self._rrf_controller_class(controller)
      end

      # Set controller if it's not explicitly set.
      kwargs[:controller] = name unless kwargs[:controller]

      has_model = !!controller_class.model
      singular = controller_class.singular
      actions = controller_class.actions
      member_actions = controller_class.member_actions

      # Use `resources` (plural) for plural model controllers to get the member `:id` scope; use
      # `resource` (singular) for everything else.
      resource_method = (has_model && !singular) ? :resources : :resource

      public_send(resource_method, name, only: [], **kwargs) do
        if has_model
          if singular
            # Singular model controller: actions and member actions are the same.
            self._rrf_route_actions(actions)
            self._rrf_route_actions(member_actions)
          else
            # Plural model controller: route collection/member actions separately.
            collection { self._rrf_route_actions(actions) }
            member { self._rrf_route_actions(member_actions) }
          end
        else
          # Non-model controller: only actions (there is no member `:id` scope).
          self._rrf_route_actions(actions)
        end

        yield if block_given?
      end
    end
  end
end
