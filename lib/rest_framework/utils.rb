module RESTFramework::Utils
  HTTP_VERB_ORDERING = %w(GET POST PUT PATCH DELETE OPTIONS HEAD)

  # Convert `extra_actions` hash to a consistent format: `{path:, methods:, kwargs:}`, and
  # additional metadata fields.
  #
  # If a controller is provided, labels will be added to any metadata fields.
  def self.parse_extra_actions(extra_actions, controller: nil)
    return (extra_actions || {}).map { |k, v|
      path = k
      metadata = {}

      # Convert structure to path/methods/kwargs.
      if v.is_a?(Hash)  # Allow kwargs to be used to define path differently from the key.
        # Symbolize keys (which also makes a copy so we don't mutate the original).
        v = v.symbolize_keys
        methods = v.delete(:methods)

        # First, remove the route metadata.
        metadata = v.delete(:metadata) || {}

        # Add label to fields.
        if controller && metadata[:fields]
          metadata[:fields] = metadata[:fields].map { |f| [f, {}] }.to_h if f.is_a?(Array)
          metadata[:fields]&.each do |field, cfg|
            cfg[:label] = controller.get_label(field) unless cfg[:label]
          end
        end

        # Override path if it's provided.
        if v.key?(:path)
          path = v.delete(:path)
        end

        # Pass any further kwargs to the underlying Rails interface.
        kwargs = v.presence
      elsif v.is_a?(Array) && v.length == 1
        methods = v[0]
      else
        methods = v
      end

      # Insert action label if it's not provided.
      if controller
        metadata[:label] ||= controller.get_label(k)
      end

      next [
        k,
        {
          path: path,
          methods: methods,
          kwargs: kwargs,
          type: :extra,
          metadata: metadata.presence,
        }.compact,
      ]
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
    current_path = "" if current_path == "/"
    current_levels = current_path.count("/")
    current_comparable_path = %r{^#{Regexp.quote(self.comparable_path(current_path))}(/|$)}

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
        current_comparable_path.match?(self.comparable_path(r.path.spec.to_s)) &&
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
        relative_path: path.split("/")[current_levels..]&.join("/").presence || "/",
        controller: r.defaults[:controller].presence,
        action: r.defaults[:action].presence,
        matches_path: matches_path,
        matches_params: matches_params,
        # The following options are only used in subsequent processing in this method.
        _levels: levels,
      }
    }.sort_by { |r|
      [
        # Sort by levels first, so routes matching closely with current request show first.
        r[:_levels],
        # Then match by path, but manually sort ':' to the end using knowledge that Ruby sorts the
        # pipe character '|' after alphanumerics.
        r[:path].tr(":", "|"),
        # Finally, match by HTTP verb.
        HTTP_VERB_ORDERING.index(r[:verb]) || 99,
      ]
    }.group_by { |r| r[:controller] }.sort_by { |c, _r|
      # Sort the controller groups by current controller first, then alphanumerically.
      [request.params[:controller] == c ? 0 : 1, c]
    }.to_h
  end

  # Custom inflector for RESTful controllers.
  def self.inflect(s, acronyms=nil)
    acronyms&.each do |acronym|
      s = s.gsub(/\b#{acronym}\b/i, acronym)
    end

    return s
  end

  # Parse fields hashes.
  def self.parse_fields_hash(fields_hash, model, exclude_associations: nil)
    parsed_fields = fields_hash[:only] || (
      model ? self.fields_for(model, exclude_associations: exclude_associations) : []
    )
    parsed_fields += fields_hash[:include] if fields_hash[:include]
    parsed_fields -= fields_hash[:exclude] if fields_hash[:exclude]

    # Warn for any unknown keys.
    (fields_hash.keys - [:only, :include, :exclude]).each do |k|
      Rails.logger.warn("RRF: Unknown key in fields hash: #{k}")
    end

    # We should always return strings, not symbols.
    return parsed_fields.map(&:to_s)
  end

  # Get the fields for a given model, including not just columns (which includes
  # foreign keys), but also associations. Note that we always return an array of
  # strings, not symbols.
  def self.fields_for(model, exclude_associations: nil)
    foreign_keys = model.reflect_on_all_associations(:belongs_to).map(&:foreign_key)

    if exclude_associations
      return model.column_names.reject { |c| c.in?(foreign_keys) }
    end

    # Add associations in addition to normal columns.
    return model.column_names.reject { |c|
      c.in?(foreign_keys)
    } + model.reflections.map { |association, ref|
      # Ignore associations for which we have custom integrations.
      if ref.class_name.in?(%w(ActiveStorage::Attachment ActiveStorage::Blob ActionText::RichText))
        next nil
      end

      # Exclude user-specified associations.
      if ref.class_name.in?(RESTFramework.config.exclude_association_classes)
        next nil
      end

      if ref.collection? && RESTFramework.config.large_reverse_association_tables&.include?(
        ref.table_name,
      )
        next nil
      end

      next association
    }.compact + model.reflect_on_all_associations(:has_one).collect(&:name).select { |n|
      n.start_with?("rich_text_")
    }.map { |n|
      n.to_s.delete_prefix("rich_text_")
    } + model.attachment_reflections.keys
  end

  # Get the sub-fields that may be serialized and filtered/ordered for a reflection.
  def self.sub_fields_for(ref)
    if !ref.polymorphic? && model = ref.klass
      sub_fields = [model.primary_key].flatten.compact
      label_fields = RESTFramework.config.label_fields

      # Preferrably find a database column to use as label.
      if match = label_fields.find { |f| f.in?(model.column_names) }
        return sub_fields + [match]
      end

      # Otherwise, find a method.
      if match = label_fields.find { |f| model.method_defined?(f) }
        return sub_fields + [match]
      end

      return sub_fields
    end

    return ["id", "name"]
  end
end
