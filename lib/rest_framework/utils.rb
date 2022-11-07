module RESTFramework::Utils
  HTTP_METHOD_ORDERING = %w(GET POST PUT PATCH DELETE)

  # Helper to take extra_actions hash and convert to a consistent format:
  # `{paths:, methods:, kwargs:}`.
  def self.parse_extra_actions(extra_actions)
    return (extra_actions || {}).map do |k, v|
      kwargs = {action: k}
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
        kwargs = kwargs.merge(v)
      elsif v.is_a?(Symbol) || v.is_a?(String)
        methods = [v]
      else
        methods = v
      end

      # Return a hash with keys: :path, :methods, :kwargs.
      {path: path, methods: methods, kwargs: kwargs}
    end
  end

  # Helper to get the first route pattern which matches the given request.
  def self.get_request_route(application_routes, request)
    application_routes.router.recognize(request) { |route, _| return route }
  end

  # Helper to normalize a path pattern by replacing URL params with generic placeholder, and
  # removing the `(.:format)` at the end.
  def self.comparable_path(path)
    return path.gsub("(.:format)", "").gsub(/:[0-9A-Za-z_-]+/, ":x")
  end

  # Helper for showing routes under a controller action; used for the browsable API.
  def self.get_routes(application_routes, request, current_route: nil)
    current_route ||= self.get_request_route(application_routes, request)
    current_path = current_route.path.spec.to_s
    current_levels = current_path.count("/")
    current_comparable_path = self.comparable_path(current_path)

    # Return routes that match our current route subdomain/pattern, grouped by controller. We
    # precompute certain properties of the route for performance.
    return application_routes.routes.select { |r|
      # We `select` first to avoid unnecessarily calculating metadata for routes we don't even want
      # to show.
      (
        (r.defaults[:subdomain].blank? || r.defaults[:subdomain] == request.subdomain) &&
        self.comparable_path(r.path.spec.to_s).start_with?(current_comparable_path) &&
        r.defaults[:controller].present? &&
        r.defaults[:action].present?
      )
    }.map { |r|
      path = r.path.spec.to_s
      levels = path.count("/")
      matches_path = current_path == path
      matches_params = r.path.required_names.length == current_route.path.required_names.length

      # Show link if the route is GET and matches URL params of current route.
      if r.verb == "GET" && matches_params
        show_link_args = current_route.path.required_names.map { |n| request.params[n] }.compact
      else
        show_link_args = nil
      end

      {
        route: r,
        verb: r.verb,
        # Starts at the number of levels in current path, and removes the `(.:format)` at the end.
        relative_path: path.split("/")[current_levels..]&.join("/")&.gsub("(.:format)", ""),
        controller: r.defaults[:controller].presence,
        action: r.defaults[:action].presence,
        show_link_args: show_link_args,
        matches_path: matches_path,
        # The following options are only used in subsequent processing in this method.
        _path: path,
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
