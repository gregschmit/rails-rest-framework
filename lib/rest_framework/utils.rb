module RESTFramework::Utils
  HTTP_VERB_ORDERING = %w(GET POST PUT PATCH DELETE OPTIONS HEAD)

  # Convert `extra_actions` hash to a consistent format: `{path:, methods:, metadata:, kwargs:}`.
  def self.parse_extra_actions(extra_actions)
    return (extra_actions || {}).map { |k, v|
      path = k
      kwargs = {}

      # Convert structure to path/methods/kwargs.
      if v.is_a?(Hash)
        # Symbolize keys (which also makes a copy so we don't mutate the original).
        v = v.symbolize_keys

        # Cast method/methods to an array.
        methods = [v.delete(:methods), v.delete(:method)].flatten.compact

        # Override path if it's provided.
        if v.key?(:path)
          path = v.delete(:path)
        end

        # Extract metadata, if provided.
        metadata = v.delete(:metadata).presence

        # Pass any further kwargs to the underlying Rails interface.
        kwargs = v
      else
        methods = [v].flatten
      end

      next [
        k,
        {
          path: path,
          methods: methods,
          metadata: metadata,
          kwargs: kwargs,
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

    # Get current route path parameters.
    path_params = current_route.required_parts.map { |n| request.path_parameters[n] }

    # Return routes that match our current route subdomain/pattern, grouped by controller. We
    # precompute certain properties of the route for performance.
    return application_routes.routes.select { |r|
      # We `select` first to avoid unnecessarily calculating metadata for routes we don't even want
      # to show.
      (r.defaults[:subdomain].blank? || r.defaults[:subdomain] == request.subdomain) &&
          current_comparable_path.match?(self.comparable_path(r.path.spec.to_s)) &&
          r.defaults[:controller].present? &&
          r.defaults[:action].present?
    }.map { |r|
      path = r.path.spec.to_s.gsub("(.:format)", "")

      # Starts at the number of levels in current path, and removes the `(.:format)` at the end.
      relative_path = path.split("/")[current_levels..]&.join("/").presence || "/"

      # This path is what would need to be concatenated onto the current path to get to the
      # destination path.
      concat_path = relative_path.gsub(/^[^\/]*/, "").presence || "/"

      levels = path.count("/")
      matches_path = current_path == path
      matches_params = r.required_parts.length == current_route.required_parts.length

      {
        route: r,
        verb: r.verb,
        path: path,
        path_with_params: r.format(
          r.required_parts.each_with_index.map { |p, i| [p, path_params[i]] }.to_h,
        ),
        relative_path: relative_path,
        concat_path: concat_path,
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
      # Note: Use `controller_path` instead of `params[:controller]` to avoid re-raising a
      # `ActionDispatch::Http::Parameters::ParseError` exception.
      [request.controller_class.controller_path == c ? 0 : 1, c]
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
  def self.parse_fields_hash(h, model, exclude_associations:, action_text:, active_storage:)
    parsed_fields = h[:only] || (
      model ? self.fields_for(
        model,
        exclude_associations: exclude_associations,
        action_text: action_text,
        active_storage: active_storage,
      ) : []
    )
    parsed_fields += h[:include].map(&:to_s) if h[:include]
    parsed_fields -= h[:exclude].map(&:to_s) if h[:exclude]
    parsed_fields -= h[:except].map(&:to_s) if h[:except]

    # Warn for any unknown keys.
    (h.keys - [:only, :except, :include, :exclude]).each do |k|
      Rails.logger.warn("RRF: Unknown key in fields hash: #{k}")
    end

    # We should always return strings, not symbols.
    return parsed_fields.map(&:to_s)
  end

  # Get the fields for a given model, including not just columns (which includes
  # foreign keys), but also associations. Note that we always return an array of
  # strings, not symbols.
  def self.fields_for(model, exclude_associations:, action_text:, active_storage:)
    foreign_keys = model.reflect_on_all_associations(:belongs_to).map(&:foreign_key)
    base_fields = model.column_names.reject { |c| c.in?(foreign_keys) }

    return base_fields if exclude_associations

    # ActionText Integration: Determine the normalized field names for action text attributes.
    atf = action_text ? model.reflect_on_all_associations(:has_one).collect(&:name).select { |n|
      n.to_s.start_with?("rich_text_")
    }.map { |n| n.to_s.delete_prefix("rich_text_") } : []

    # ActiveStorage Integration: Determine the normalized field names for active storage attributes.
    asf = active_storage ? model.attachment_reflections.keys : []

    # Associations:
    associations = model.reflections.map { |association, ref|
      # Ignore associations for which we have custom integrations.
      if ref.class_name.in?(%w(ActionText::RichText ActiveStorage::Attachment ActiveStorage::Blob))
        next nil
      end

      if ref.collection? && RESTFramework.config.large_reverse_association_tables&.include?(
        ref.table_name,
      )
        next nil
      end

      next association
    }.compact

    return base_fields + associations + atf + asf
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

  # Get a field's id/ids variation.
  def self.id_field_for(field, reflection)
    if reflection.collection?
      return "#{field.singularize}_ids"
    elsif reflection.belongs_to?
      # The id field for belongs_to is always the foreign key column name, even if the
      # association is named differently.
      return reflection.foreign_key
    end

    return nil
  end

  # Wrap a serializer with an adapter if it is an ActiveModel::Serializer.
  def self.wrap_ams(s)
    if defined?(ActiveModel::Serializer) && (s < ActiveModel::Serializer)
      return RESTFramework::ActiveModelSerializerAdapterFactory.for(s)
    end

    return s
  end
end
