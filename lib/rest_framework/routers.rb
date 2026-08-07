require "action_dispatch/routing/mapper"

module ActionDispatch::Routing
  class Mapper
    # Resolve a controller class from a route name and the current scope. The name must match the
    # controller exactly (camelized, plus `Controller`) — there is no pluralization fallback.
    def _rrf_controller_class(name)
      mod = @scope[:module] ? @scope[:module].to_s.camelize.constantize : Object
      mod.const_get("#{name.to_s.camelize}Controller")
    end

    # Route each action from a controller's action store. `helpers: false` routes every action
    # unnamed (`as: nil`), so the resource contributes no URL/path helpers.
    def _rrf_route_actions(actions, helpers: true)
      actions.each_value do |spec|
        # Delegated actions keep their declared action name (so routing and OpenAPI show the real
        # name); `method_for_action` redirects dispatch to `rrf_delegate`, which needs the scope.
        kwargs = spec.kwargs
        if !spec.builtin && spec.metadata&.[](:delegate)
          kwargs = kwargs.merge(rrf_delegate_scope: spec.type)
        end
        kwargs = kwargs.merge(as: nil) unless helpers

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

    # Route a single controller from its action store. Whether it routes as a singular `resource` or
    # a plural `resources` is decided by the controller's own config (`singular`, and whether it has
    # a `model`) — not by the method name: a plural model controller gets collection/member scopes,
    # while singular and non-model controllers route everything at the root. Pass a block to nest
    # resources like Rails' `resources` (the nested controller resolves in the current scope). Pass
    # `helpers: false` to route the resource without URL/path helpers — handy when a singular and a
    # plural resource of the same model would otherwise claim the same helper name.
    def rest_resource(name, **kwargs)
      controller = kwargs.delete(:controller) || name
      if controller.is_a?(Class)
        controller_class = controller
      else
        controller_class = self._rrf_controller_class(controller)
      end

      # Set controller if it's not explicitly set.
      kwargs[:controller] = name unless kwargs[:controller]

      # `helpers:` is ours, not Rails' — pull it out before forwarding the rest to the router.
      helpers = kwargs.delete(:helpers) != false

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
            self._rrf_route_actions(actions, helpers: helpers)
            self._rrf_route_actions(member_actions, helpers: helpers)
          else
            # Plural model controller: route collection/member actions separately.
            collection { self._rrf_route_actions(actions, helpers: helpers) }
            member { self._rrf_route_actions(member_actions, helpers: helpers) }
          end
        else
          # Non-model controller: only actions (there is no member `:id` scope).
          self._rrf_route_actions(actions, helpers: helpers)
        end

        yield if block_given?
      end
    end

    # Route several controllers that share the same options in one call — handy for condensing a
    # namespace. Per-name options (`path:`, `as:`, `controller:`) and a block only make sense for a
    # single controller, so they're rejected when several names are given. The `s` is about routing
    # multiple controllers, not plural routes — a single plural controller is still `rest_resource`.
    def rest_resources(*names, **kwargs, &block)
      if names.size > 1 && (block || (kwargs.keys & [ :path, :as, :controller ]).any?)
        raise ArgumentError, "rest_resources: per-name options and a block require a single name"
      end

      names.each { |name| rest_resource(name, **kwargs, &block) }
    end
  end
end
