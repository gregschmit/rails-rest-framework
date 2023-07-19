# A simple filtering backend that supports filtering a recordset based on query parameters.
class RESTFramework::Filters::ModelQueryFilter < RESTFramework::Filters::BaseFilter
  NIL_VALUES = ["nil", "null"].freeze

  # Get a list of filterset fields for the current action.
  def _get_fields
    # Always return a list of strings; `@controller.get_fields` already does this.
    return @controller.class.filterset_fields&.map(&:to_s) || @controller.get_fields
  end

  # Filter params for keys allowed by the current action's filterset_fields/fields config.
  def _get_filter_params
    fields = self._get_fields
    includes = []

    filter_params = @controller.request.query_parameters.select { |p, _|
      # Remove any trailing `__in` from the field name.
      field = p.chomp("__in")

      # Remove any associations whose sub-fields are not filterable.
      if match = /(.*)\.(.*)/.match(field)
        field, sub_field = match[1..2]
        next false unless field.in?(fields)

        sub_fields = @controller.class.get_field_config(field)[:sub_fields] || []
        if sub_field.in?(sub_fields)
          includes << field.to_sym
          next true
        end

        next false
      end

      next field.in?(fields)
    }.map { |p, v|
      # Convert fields ending in `__in` to array values.
      if p.end_with?("__in")
        p = p.chomp("__in")
        v = v.split(",").map { |v| v.in?(NIL_VALUES) ? nil : v }
      end

      # Convert "nil" and "null" to nil.
      v = nil if v.in?(NIL_VALUES)

      [p, v]
    }.to_h.symbolize_keys

    return filter_params, includes
  end

  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    filter_params, includes = self._get_filter_params

    if filter_params.any?
      if includes.any?
        data = data.includes(*includes)
      end

      return data.where(**filter_params)
    end

    return data
  end
end

# Alias for convenience.
RESTFramework::ModelQueryFilter = RESTFramework::Filters::ModelQueryFilter
