# A filter backend which handles ordering of the recordset.
class RESTFramework::Filters::OrderingFilter < RESTFramework::Filters::BaseFilter
  # Get a list of ordering fields for the current action.
  def _get_fields
    @controller.class.ordering_fields&.map(&:to_s) || @controller.get_fields
  end

  # Convert ordering string to an ordering configuration.
  def _get_ordering
    return nil unless param = @controller.class.ordering_query_param.presence

    # Ensure ordering_fields are strings since the split param will be strings.
    fields = self._get_fields
    order_string = @controller.params[param]

    if order_string.present?
      ordering = {}.with_indifferent_access

      order_string = order_string.join(",") if order_string.is_a?(Array)
      order_string.split(",").map(&:strip).each do |field|
        if field[0] == "-"
          column = field[1..-1]
          direction = :desc
        else
          column = field
          direction = :asc
        end

        next if !column.in?(fields) && !column.split(".").first.in?(fields)

        ordering[column] = direction
      end

      return ordering
    end

    nil
  end

  # Order data according to the request query parameters.
  def filter_data(data)
    ordering = self._get_ordering
    reorder = !@controller.class.ordering_no_reorder

    if ordering && !ordering.empty?
      return data.send(reorder ? :reorder : :order, ordering)
    end

    data
  end
end

# Alias for convenience.
RESTFramework::OrderingFilter = RESTFramework::Filters::OrderingFilter
