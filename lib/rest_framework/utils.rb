module RESTFramework::Utils
  HTTP_METHOD_ORDERING = %w(GET POST PUT PATCH DELETE OPTIONS HEAD)

  # Convert `extra_actions` hash to a consistent format: `{path:, methods:, kwargs:}`.
  def self.parse_extra_actions(extra_actions)
    return (extra_actions || {}).map { |k, v|
      path = k

      # Convert structure to path/methods/kwargs.
      if v.is_a?(Hash)  # Allow kwargs to be used to define path differently from the key.
        v = v.symbolize_keys

        # Ensure methods is an array.
        if v[:methods].is_a?(String) || v[:methods].is_a?(Symbol)
          methods = [v.delete(:methods)]
        else
          methods = v.delete(:methods)
        end

        # Override path if it's provided.
        if v.key?(:path)
          path = v.delete(:path)
        end

        # Pass any further kwargs to the underlying Rails interface.
        kwargs = v.presence&.except(:delegate)
      elsif v.is_a?(Symbol) || v.is_a?(String)
        methods = [v]
      else
        methods = v
      end

      [k, {path: path, methods: methods, kwargs: kwargs}.compact]
    }.to_h
  end

  # Get actions which should be skipped for a given controller.
  def self.get_skipped_builtin_actions(controller_class)
    return (
      RESTFramework::BUILTIN_ACTIONS.keys + RESTFramework::BUILTIN_MEMBER_ACTIONS.keys
    ).reject do |action|
      controller_class.method_defined?(action)
    end
  end

  # Get the first route pattern which matches the given request.
  def self.get_request_route(application_routes, request)
    application_routes.router.recognize(request) { |route, _| return route }
  end

  # Normalize a path pattern by replacing URL params with generic placeholder, and removing the
  # `(.:format)` at the end.
  def self.comparable_path(path)
    return path.gsub("(.:format)", "").gsub(/:[0-9A-Za-z_-]+/, ":x")
  end

  # Show routes under a controller action; used for the browsable API.
  def self.get_routes(application_routes, request, current_route: nil)
    current_route ||= self.get_request_route(application_routes, request)
    current_path = current_route.path.spec.to_s.gsub("(.:format)", "")
    current_levels = current_path.count("/")
    current_comparable_path = self.comparable_path(current_path)

    # Add helpful properties of the current route.
    path_args = current_route.required_parts.map { |n| request.path_parameters[n] }
    route_props = {
      with_path_args: ->(r) {
        r.format(r.required_parts.each_with_index.map { |p, i| [p, path_args[i]] }.to_h)
      },
    }

    # Return routes that match our current route subdomain/pattern, grouped by controller. We
    # precompute certain properties of the route for performance.
    return route_props, application_routes.routes.select { |r|
      # We `select` first to avoid unnecessarily calculating metadata for routes we don't even want
      # to show.
      (
        (r.defaults[:subdomain].blank? || r.defaults[:subdomain] == request.subdomain) &&
        self.comparable_path(r.path.spec.to_s).start_with?(current_comparable_path) &&
        r.defaults[:controller].present? &&
        r.defaults[:action].present?
      )
    }.map { |r|
      path = r.path.spec.to_s.gsub("(.:format)", "")
      levels = path.count("/")
      matches_path = current_path == path
      matches_params = r.required_parts.length == current_route.required_parts.length

      {
        route: r,
        verb: r.verb,
        path: path,
        # Starts at the number of levels in current path, and removes the `(.:format)` at the end.
        relative_path: path.split("/")[current_levels..]&.join("/"),
        controller: r.defaults[:controller].presence,
        action: r.defaults[:action].presence,
        matches_path: matches_path,
        matches_params: matches_params,
        # The following options are only used in subsequent processing in this method.
        _levels: levels,
      }
    }.sort_by { |r|
      # Sort by levels first, so the routes matching closely with current request show first, then
      # by the path, and finally by the HTTP verb.
      [r[:_levels], r[:_path], HTTP_METHOD_ORDERING.index(r[:verb]) || 99]
    }.group_by { |r| r[:controller] }.sort_by { |c, _r|
      # Sort the controller groups by current controller first, then depth, then alphanumerically.
      [request.params[:controller] == c ? 0 : 1, c.count("/"), c]
    }.to_h
  end
end
