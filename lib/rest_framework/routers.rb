require 'action_dispatch/routing/mapper'
require_relative 'utils'

module ActionDispatch::Routing
  class Mapper
    # Internal interface to get the controller class from the name and current scope.
    protected def _get_controller_class(name, pluralize: true, fallback_reverse_pluralization: true)
      # get class name
      name = name.to_s.camelize  # camelize to leave plural names plural
      name = name.pluralize if pluralize
      if name == name.pluralize
        name_reverse = name.singularize
      else
        name_reverse = name.pluralize
      end
      name += "Controller"
      name_reverse += "Controller"

      # get scope for the class
      if @scope[:module]
        mod = @scope[:module].to_s.classify.constantize
      else
        mod = Object
      end

      # convert class name to class
      begin
        controller = mod.const_get(name)
      rescue NameError
        if fallback_reverse_pluralization
          controller = mod.const_get(name_reverse)
        else
          raise
        end
      end

      return controller
    end

    # Interal interface for routing extra actions.
    protected def _route_extra_actions(actions, &block)
      actions.each do |action_config|
        action_config[:methods].each do |m|
          public_send(m, action_config[:path], **action_config[:kwargs])
        end
        yield if block_given?
      end
    end

    # Internal core implementation of the `rest_resource(s)` router, both singular and plural.
    # @param default_singular [Boolean] the default plurality of the resource if the plurality is
    #   not otherwise defined by the controller
    # @param name [Symbol] the resource name, from which path and controller are deduced by default
    # @param skip_undefined [Boolean] whether we should skip routing undefined resourceful actions
    protected def _rest_resources(default_singular, name, skip_undefined: true, **kwargs, &block)
      controller = kwargs.delete(:controller) || name
      if controller.is_a?(Class)
        controller_class = controller
      else
        controller_class = self._get_controller_class(controller, pluralize: !default_singular)
      end

      # Set controller if it's not explicitly set.
      kwargs[:controller] = name unless kwargs[:controller]

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
      skip_undefined = kwargs.delete(:skip_undefined) || true
      skip = controller_class.get_skip_actions(skip_undefined: skip_undefined)
      public_send(resource_method, name, except: skip, **kwargs) do
        if controller_class.respond_to?(:extra_member_actions)
          member do
            actions = RESTFramework::Utils::parse_extra_actions(
              controller_class.extra_member_actions
            )
            self._route_extra_actions(actions)
          end
        end

        collection do
          actions = RESTFramework::Utils::parse_extra_actions(controller_class.extra_actions)
          self._route_extra_actions(actions)
        end

        yield if block_given?
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

      # Route actions using the resourceful router, but skip all builtin actions.
      actions = RESTFramework::Utils::parse_extra_actions(controller_class.extra_actions)
      public_send(:resource, name, only: [], **kwargs) do
        # Route a root for this resource.
        if route_root_to
          get '', action: route_root_to
        end

        self._route_extra_actions(actions, &block)
      end
    end

    # Route a controller's `#root` to '/' in the current scope/namespace, along with other actions.
    def rest_root(name=nil, **kwargs, &block)
      # By default, use RootController#root.
      root_action = kwargs.delete(:action) || :root
      controller = kwargs.delete(:controller) || name || :root

      # Remove path if name is nil (routing to the root of current namespace).
      unless name
        kwargs[:path] = ''
      end

      return rest_route(controller, route_root_to: root_action, **kwargs) do
        yield if block_given?
      end
    end

  end
end
