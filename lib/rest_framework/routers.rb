require 'rails'
require 'action_dispatch/routing/mapper'

module ActionDispatch::Routing
  class Mapper
    # Private interface to get the controller class from the name and current scope.
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
        controller = mod.const_get(name, false)
      rescue NameError
        if fallback_reverse_pluralization
          controller = mod.const_get(name_reverse, false)
        else
          raise
        end
      end

      return controller
    end

    # Core implementation of the `rest_resource(s)` router, both singular and plural.
    # @param default_singular [Boolean] the default plurality of the resource if the plurality is
    #   not otherwise defined by the controller
    # @param name [Symbol] the resource name, from which path and controller are deduced by default
    # @param skip_undefined [Boolean] whether we should skip routing undefined actions
    protected def _rest_resources(default_singular, name, skip_undefined: true, **kwargs, &block)
      controller = kwargs[:controller] || name
      if controller.is_a?(Class)
        controller_class = controller
      else
        controller_class = _get_controller_class(controller, pluralize: !default_singular)
      end

      # set controller if it's not explicitly set
      kwargs[:controller] = name unless kwargs[:controller]

      # determine plural/singular resource
      if kwargs.delete(:force_singular)
        singular = true
      elsif kwargs.delete(:force_plural)
        singular = false
      elsif !controller_class.singleton_controller.nil?
        singular = controller_class.singleton_controller
      else
        singular = default_singular
      end
      resource_method = singular ? :resource : :resources

      # call either `resource` or `resources`, passing appropriate modifiers
      skip_undefined = kwargs.delete(:skip_undefined) || true
      skip = controller_class.skip_actions(skip_undefined: skip_undefined)
      public_send(resource_method, name, except: skip, **kwargs) do
        if controller_class.respond_to?(:extra_member_actions)
          member do
            actions = controller_class.extra_member_actions
            actions = actions.select { |k,v| controller_class.method_defined?(k) } if skip_undefined
            actions.each do |action, methods|
              methods = [methods] if methods.is_a?(Symbol) || methods.is_a?(String)
              methods.each do |m|
                public_send(m, action)
              end
            end
          end
        end

        collection do
          actions = controller_class.extra_actions
          actions = actions.select { |k,v| controller_class.method_defined?(k) } if skip_undefined
          actions.each do |action, methods|
            methods = [methods] if methods.is_a?(Symbol) || methods.is_a?(String)
            methods.each do |m|
              public_send(m, action)
            end
          end
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

    # Route a controller's `#root` to '/' in the current scope/namespace, along with other actions.
    # @param label [Symbol] the snake_case name of the controller
    def rest_root(path=nil, **kwargs, &block)
      # by default, use RootController#root
      root_action = kwargs.delete(:action) || :root
      controller = kwargs.delete(:controller) || path || :root
      path = path.to_s

      # route the root
      get path, controller: controller, action: root_action

      # route any additional actions
      controller_class = self._get_controller_class(controller, pluralize: false)
      controller_class.extra_actions.each do |action, methods|
        methods = [methods] if methods.is_a?(Symbol) || methods.is_a?(String)
        methods.each do |m|
          public_send(m, File.join(path, action.to_s), controller: controller, action: action)
        end
        yield if block_given?
      end
    end

  end
end
