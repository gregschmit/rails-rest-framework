# A simple filtering backend that supports filtering a recordset based on query parameters.
class RESTFramework::ModelQueryFilter < RESTFramework::BaseFilter
  # Get a list of filterset fields for the current action.
  def _get_fields
    # Always return a list of strings; `@controller.get_fields` already does this.
    return @controller.class.filterset_fields&.map(&:to_s) || @controller.get_fields
  end

  # Filter params for keys allowed by the current action's filterset_fields/fields config.
  def _get_filter_params
    fields = self._get_fields

    return @controller.request.query_parameters.select { |p, _|
      # Remove any trailing `__in` from the field name.
      field = p.chomp("__in")

      # Remove any associations whose sub-fields are not filterable.
      if match = /(.*)\.(.*)/.match(field)
        field, sub_field = match[1..2]
        next false unless field.in?(fields)

        sub_fields = @controller.class.get_field_config(field)[:sub_fields] || []
        next sub_field.in?(sub_fields)
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
      return data.where(**filter_params)
    end

    return data
  end
end
