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
  # Filter params for keys allowed by the current action's filterset_fields/fields config.
  def _get_filter_params
    # Map filterset fields to strings because query parameter keys are strings.
    fields = @controller.get_filterset_fields.map(&:to_s)

    return @controller.request.query_parameters.select { |p, _| fields.include?(p) }
  end

  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    filter_params = self._get_filter_params.symbolize_keys
    unless filter_params.blank?
      return data.where(**filter_params)
    end

    return data
  end
end

# A filter backend which handles ordering of the recordset.
class RESTFramework::ModelOrderingFilter < RESTFramework::BaseFilter
  # Convert ordering string to an ordering configuration.
  def _get_ordering
    return nil if @controller.class.ordering_query_param.blank?

    # Ensure ordering_fields are strings since the split param will be strings.
    ordering_fields = @controller.get_ordering_fields.map(&:to_s)
    order_string = @controller.params[@controller.class.ordering_query_param]

    unless order_string.blank?
      ordering = {}.with_indifferent_access
      order_string.split(",").each do |field|
        if field[0] == "-"
          column = field[1..-1]
          direction = :desc
        else
          column = field
          direction = :asc
        end
        if column.in?(ordering_fields)
          ordering[column] = direction
        end
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
      return data.send(reorder ? :reorder : :order, _get_ordering)
    end

    return data
  end
end

# Multi-field text searching on models.
class RESTFramework::ModelSearchFilter < RESTFramework::BaseFilter
  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    fields = @controller.get_search_fields
    search = @controller.request.query_parameters[@controller.class.search_query_param]

    # Ensure we use array conditions to prevent SQL injection.
    unless search.blank?
      return data.where(
        fields.map { |f|
          "CAST(#{f} AS CHAR) #{@controller.class.search_ilike ? "ILIKE" : "LIKE"} ?"
        }.join(" OR "),
        *(["%#{search}%"] * fields.length),
      )
    end

    return data
  end
end
