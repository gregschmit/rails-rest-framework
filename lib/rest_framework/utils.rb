module RESTFramework::Utils
  # Helper to take extra_actions hash and convert to a consistent format:
  # `{paths:, methods:, kwargs:}`.
  def self.parse_extra_actions(extra_actions)
    return (extra_actions || {}).map do |k, v|
      kwargs = {action: k}
      path = k

      # Convert structure to path/methods/kwargs.
      if v.is_a?(Hash)  # allow kwargs
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

  # Helper to get the current route pattern, stripped of the `(:format)` segment.
  def self.get_route_pattern(application_routes, request)
    application_routes.router.recognize(request) do |route, _, _|
      return route.path.spec.to_s.gsub(/\(\.:format\)$/, "")
    end
  end

  # Helper for showing routes under a controller action, used for the browsable API.
  def self.get_routes(application_routes, request)
    current_pattern = self.get_route_pattern(application_routes, request)
    current_subdomain = request.subdomain.presence

    # Return routes that match our current route subdomain/pattern, grouped by controller.
    return application_routes.routes.map { |r|
      {
        verb: r.verb,
        path: r.path.spec.to_s,
        action: r.defaults[:action].presence,
        controller: r.defaults[:controller].presence,
        subdomain: r.defaults[:subdomain].presence,
        route_app: r.app&.app&.inspect&.presence,
      }
    }.select { |r|
      r[:subdomain] == current_subdomain && r[:path].start_with?(current_pattern)
    }.group_by { |r| r[:controller] }
  end
end
