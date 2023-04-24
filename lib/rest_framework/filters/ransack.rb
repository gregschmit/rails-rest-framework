# Adapter for the `ransack` gem.
class RESTFramework::RansackFilter < RESTFramework::BaseFilter
  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    q = @controller.request.query_parameters[@controller.ransack_query_param]

    if q.present?
      distinct = @controller.ransack_distinct

      # Determine if `distinct` is determined by query param.
      if distinct_query_param = @controller.ransack_distinct_query_param
        distinct_from_query = ActiveRecord::Type::Boolean.new.cast(
          @controller.request.query_parameters[distinct_query_param],
        )
        unless distinct_from_query.nil?
          distinct = distinct_from_query
        end
      end

      return data.ransack(q, @controller.ransack_options).result(distinct: distinct)
    end

    return data
  end
end
