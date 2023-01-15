class RESTFramework::BaseFilter
  def initialize(controller:)
    @controller = controller
  end

  def get_filtered_data(data)
    raise NotImplementedError
  end
end

# A simple filtering backend that supports filtering a recordset based on fields defined on the
# controller class.
class RESTFramework::ModelFilter < RESTFramework::BaseFilter
  # Get a list of filterset fields for the current action. Fallback to columns because we don't want
  # to try filtering by any query parameter because that could clash with other query parameters.
  def _get_fields
    return @_get_fields ||= (
      @controller.class.filterset_fields || @controller.get_fields(fallback: true)
    ).map(&:to_s)
  end

  # Filter params for keys allowed by the current action's filterset_fields/fields config.
  def _get_filter_params
    # Map filterset fields to strings because query parameter keys are strings.
    fields = self._get_fields
    @associations = []

    return @controller.request.query_parameters.select { |p, _|
      # Remove any trailing `__in` from the field name.
      field = p.chomp("__in")

      # Remove any associations whose sub-fields are not filterable. Also populate `@associations`
      # so the caller can include them.
      if match = /(.*)\.(.*)/.match(field)
        field, sub_field = match[1..2]
        next false unless field.in?(fields)

        sub_fields = @controller.class.get_field_config(field)[:sub_fields]
        if sub_field.in?(sub_fields)
          @associations << field.to_sym
          next true
        end

        next false
      end

      next field.in?(fields)
    }.map { |p, v|
      # Convert fields ending in `__in` to array values.
      if p.end_with?("__in")
        p = p.chomp("__in")
        v = v.split(",")
      end

      # Convert "nil" and "null" to nil.
      if v == "nil" || v == "null"
        v = nil
      end

      [p, v]
    }.to_h.symbolize_keys
  end

  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    if filter_params = self._get_filter_params.presence
      # Include any associations.
      data = data.includes(*@associations) unless @associations.empty?

      return data.where(**filter_params)
    end

    return data
  end
end

# A filter backend which handles ordering of the recordset.
class RESTFramework::ModelOrderingFilter < RESTFramework::BaseFilter
  # Get a list of ordering fields for the current action. Do not fallback to columns in case the
  # user wants to order by a virtual column.
  def _get_fields
    return @_get_fields ||= (
      @controller.class.ordering_fields || @controller.get_fields
    )&.map(&:to_s)
  end

  # Convert ordering string to an ordering configuration.
  def _get_ordering
    return nil if @controller.class.ordering_query_param.blank?

    @associations = []

    # Ensure ordering_fields are strings since the split param will be strings.
    fields = self._get_fields
    order_string = @controller.params[@controller.class.ordering_query_param]

    if order_string.present?
      ordering = {}.with_indifferent_access
      order_string.split(",").each do |field|
        if field[0] == "-"
          column = field[1..-1]
          direction = :desc
        else
          column = field
          direction = :asc
        end
        next unless !fields || column.in?(fields)

        # Populate any `@associations` so the caller can include them.
        if match = /(.*)\.(.*)/.match(column)
          association, sub_field = match[1..2]
          @associations << association.to_sym

          # Also, due to Rails weirdness, we need to convert the association name to the table name.
          table_name = @controller.class.get_model.reflections[association].table_name
          column = "#{table_name}.#{sub_field}"
        end

        ordering[column] = direction
      end
      return ordering
    end

    return nil
  end

  # Order data according to the request query parameters.
  def get_filtered_data(data)
    ordering = self._get_ordering
    reorder = !@controller.class.ordering_no_reorder

    if ordering && !ordering.empty?
      # Include any associations.
      data = data.includes(*@associations) unless @associations.empty?

      return data.send(reorder ? :reorder : :order, ordering)
    end

    return data
  end
end

# Multi-field text searching on models.
class RESTFramework::ModelSearchFilter < RESTFramework::BaseFilter
  # Get a list of search fields for the current action. Fallback to columns because we need an
  # explicit list of columns to search on, so `nil` is useless in this context.
  def _get_fields
    return @controller.class.search_fields || @controller.get_fields(fallback: true)
  end

  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    fields = self._get_fields
    search = @controller.request.query_parameters[@controller.class.search_query_param]

    # Ensure we use array conditions to prevent SQL injection.
    if search.present? && !fields.empty?
      return data.where(
        fields.map { |f|
          "CAST(#{f} AS VARCHAR) #{@controller.class.search_ilike ? "ILIKE" : "LIKE"} ?"
        }.join(" OR "),
        *(["%#{search}%"] * fields.length),
      )
    end

    return data
  end
end
