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
    fields = @controller.send(:get_filterset_fields)
    return @controller.request.query_parameters.select { |p|
      fields.include?(p)
    }.to_h.symbolize_keys  # convert from HashWithIndifferentAccess to Hash w/keys
  end

  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    filter_params = self._get_filter_params
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
    ordering_fields = @controller.send(:get_ordering_fields)

    order_string = @controller.params[@controller.class.ordering_query_param]
    unless order_string.blank?
      ordering = {}
      order_string.split(',').each do |field|
        if field[0] == '-'
          column = field[1..-1]
          direction = :desc
        else
          column = field
          direction = :asc
        end
        if column.in?(ordering_fields)
          ordering[column.to_sym] = direction
        end
      end
      return ordering
    end

    return nil
  end

  # Order data according to the request query parameters.
  def get_filtered_data(data)
    ordering = self._get_ordering
    if ordering && !ordering.empty?
      return data.order(_get_ordering)
    end
    return data
  end
end


# TODO: implement searching within fields rather than exact match filtering (ModelFilter)
# class RESTFramework::ModelSearchFilter < RESTFramework::BaseFilter
# end
