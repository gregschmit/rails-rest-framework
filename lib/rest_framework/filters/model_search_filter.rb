# Multi-field text searching on models.
class RESTFramework::Filters::ModelSearchFilter < RESTFramework::Filters::BaseFilter
  # Get a list of search fields for the current action.
  def _get_fields
    if search_fields = @controller.search_fields
      return search_fields&.map(&:to_s)
    end

    columns = @controller.class.get_model.column_names
    return @controller.get_fields.select { |f|
      f.in?(RESTFramework.config.search_columns) && f.in?(columns)
    }
  end

  # Filter data according to the request query parameters.
  def get_filtered_data(data)
    search = @controller.request.query_parameters[@controller.search_query_param]

    if search.present?
      if fields = self._get_fields.presence
        # MySQL doesn't support casting to VARCHAR, so we need to use CHAR instead.
        data_type = if data.connection.adapter_name =~ /mysql/i
          "CHAR"
        else
          # Sufficient for both PostgreSQL and SQLite.
          "VARCHAR"
        end

        # Ensure we pass user input as arguments to prevent SQL injection.
        return data.where(
          fields.map { |f|
            "CAST(#{f} AS #{data_type}) #{@controller.search_ilike ? "ILIKE" : "LIKE"} ?"
          }.join(" OR "),
          *(["%#{search}%"] * fields.length),
        )
      end
    end

    return data
  end
end

# Alias for convenience.
RESTFramework::ModelSearchFilter = RESTFramework::Filters::ModelSearchFilter
