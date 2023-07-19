# A filter backend which handles ordering of the recordset.
class RESTFramework::Filters::ModelOrderingFilter < RESTFramework::Filters::BaseFilter
  # Get a list of ordering fields for the current action.
  def _get_fields
    return @controller.ordering_fields&.map(&:to_s) || @controller.get_fields
  end

  # Convert ordering string to an ordering configuration.
  def _get_ordering
    return nil if @controller.ordering_query_param.blank?

    # Ensure ordering_fields are strings since the split param will be strings.
    fields = self._get_fields
    order_string = @controller.params[@controller.ordering_query_param]

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

        next if !column.in?(fields) && !column.split(".").first.in?(fields)

        ordering[column] = direction
      end

      return ordering
    end

    return nil
  end

  # Order data according to the request query parameters.
  def get_filtered_data(data)
    ordering = self._get_ordering
    reorder = !@controller.ordering_no_reorder

    if ordering && !ordering.empty?
      return data.send(reorder ? :reorder : :order, ordering)
    end

    return data
  end
end

# Alias for convenience.
RESTFramework::ModelOrderingFilter = RESTFramework::Filters::ModelOrderingFilter
