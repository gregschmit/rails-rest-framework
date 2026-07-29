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

    # Unified REST route helper, driven by the controller's action store. Plural model controllers
    # get collection/member scopes; singular and non-model controllers route everything at the root.
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
      collection_actions = controller_class.actions
      member_actions = controller_class.member_actions

      # Use `resources` (plural) for plural model controllers to get the member `:id` scope; use
      # `resource` (singular) for everything else.
      resource_method = (has_model && !singular) ? :resources : :resource

      public_send(resource_method, name, only: [], **kwargs) do
        if has_model && !singular
          collection { self._rrf_route_actions(collection_actions) }
          member { self._rrf_route_actions(member_actions) }
        elsif has_model
          # Singular model controller: member and collection actions all route at the root path.
          self._rrf_route_actions(member_actions)
          self._rrf_route_actions(collection_actions)
        else
          # Non-model controller: only collection actions (there is no member `:id` scope).
          self._rrf_route_actions(collection_actions)
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
