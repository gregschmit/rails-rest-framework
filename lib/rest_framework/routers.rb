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
          rescue
            reraise = true
          end

          if reraise
            raise
          end
        else
          raise
        end
      end

      return controller
    end

    # Interal interface for routing extra actions.
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

    # Internal core implementation of the `rest_resource(s)` router, both singular and plural.
    # @param default_singular [Boolean] the default plurality of the resource if the plurality is
    #   not otherwise defined by the controller
    # @param name [Symbol] the resource name, from which path and controller are deduced by default
    def _rest_resources(default_singular, name, **kwargs, &block)
      controller = kwargs.delete(:controller) || name
      if controller.is_a?(Class)
        controller_class = controller
      else
        controller_class = self._get_controller_class(controller, pluralize: !default_singular)
      end

      # Set controller if it's not explicitly set.
      kwargs[:controller] = name unless kwargs[:controller]

      # Passing `unscoped: true` will prevent a nested resource from being scoped.
      unscoped = kwargs.delete(:unscoped)

      # Determine plural/singular resource.
      force_singular = kwargs.delete(:force_singular)
      force_plural = kwargs.delete(:force_plural)
      if force_singular
        singular = true
      elsif force_plural
        singular = false
      elsif !controller_class.singleton_controller.nil?
        singular = controller_class.singleton_controller
      else
        singular = default_singular
      end
      resource_method = singular ? :resource : :resources

      # Call either `resource` or `resources`, passing appropriate modifiers.
      skip = RESTFramework::Utils.get_skipped_builtin_actions(controller_class)
      public_send(resource_method, name, except: skip, **kwargs) do
        if controller_class.respond_to?(:extra_member_actions)
          member do
            self._route_extra_actions(controller_class.extra_member_actions)
          end
        end

        collection do
          # Route extra controller-defined actions.
          self._route_extra_actions(controller_class.extra_actions)

          # Route extra RRF-defined actions.
          RESTFramework::RRF_BUILTIN_ACTIONS.each do |action, methods|
            next unless controller_class.method_defined?(action)

            [methods].flatten.each do |m|
              public_send(m, "", action: action) if self.respond_to?(m)
            end
          end

          # Route bulk actions, if configured.
          RESTFramework::RRF_BUILTIN_BULK_ACTIONS.each do |action, methods|
            next unless controller_class.method_defined?(action)

            [methods].flatten.each do |m|
              public_send(m, "", action: action) if self.respond_to?(m)
            end
          end
        end

        if unscoped
          yield if block_given?
        else
          scope(module: name, as: name) do
            yield if block_given?
          end
        end
      end
    end

    # Public interface for creating singular RESTful resource routes.
    def rest_resource(*names, **kwargs, &block)
      names.each do |n|
        self._rest_resources(true, n, **kwargs, &block)
      end
    end

    # Public interface for creating plural RESTful resource routes.
    def rest_resources(*names, **kwargs, &block)
      names.each do |n|
        self._rest_resources(false, n, **kwargs, &block)
      end
    end

    # Route a controller without the default resourceful paths.
    def rest_route(name=nil, **kwargs, &block)
      controller = kwargs.delete(:controller) || name
      route_root_to = kwargs.delete(:route_root_to)
      if controller.is_a?(Class)
        controller_class = controller
      else
        controller_class = self._get_controller_class(controller, pluralize: false)
      end

      # Set controller if it's not explicitly set.
      kwargs[:controller] = name unless kwargs[:controller]

      # Passing `unscoped: true` will prevent a nested resource from being scoped.
      unscoped = kwargs.delete(:unscoped)

      # Route actions using the resourceful router, but skip all builtin actions.
      public_send(:resource, name, only: [], **kwargs) do
        # Route a root for this resource.
        if route_root_to
          get("", action: route_root_to, as: "")
        end

        collection do
          # Route extra controller-defined actions.
          self._route_extra_actions(controller_class.extra_actions)

          # Route extra RRF-defined actions.
          RESTFramework::RRF_BUILTIN_ACTIONS.each do |action, methods|
            next unless controller_class.method_defined?(action)

            [methods].flatten.each do |m|
              public_send(m, "", action: action) if self.respond_to?(m)
            end
          end
        end

        if unscoped
          yield if block_given?
        else
          scope(module: name, as: name) do
            yield if block_given?
          end
        end
      end
    end

    # Route a controller's `#root` to '/' in the current scope/namespace, along with other actions.
    def rest_root(name=nil, **kwargs, &block)
      # By default, use RootController#root.
      root_action = kwargs.delete(:action) || :root
      controller = kwargs.delete(:controller) || name || :root

      # Remove path if name is nil (routing to the root of current namespace).
      unless name
        kwargs[:path] = ""
      end

      return rest_route(controller, route_root_to: root_action, **kwargs) do
        yield if block_given?
      end
    end
  end
end
