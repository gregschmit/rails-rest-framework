class RESTFramework::Filters::SearchFilter < RESTFramework::Filters::BaseFilter
  # Get a list of search fields for the current action.
  def _get_fields
    if search_fields = @controller.class.search_fields
      return search_fields&.map(&:to_s)
    end

    columns = @controller.class.model.column_names
    @controller.get_fields.select { |f|
      f.in?(RESTFramework.config.search_columns) && f.in?(columns)
    }
  end

  # Filter data according to the request query parameters.
  def filter_data(data)
    search = @controller.request.query_parameters[@controller.class.search_query_param]

    if search.present?
      if fields = self._get_fields.presence
        # MySQL doesn't support casting to VARCHAR, so we need to use CHAR instead.
        data_type = if data.connection.adapter_name =~ /mysql|trilogy/i
          "CHAR"
        else
          # Sufficient for both PostgreSQL and SQLite.
          "VARCHAR"
        end

        conn = data.connection
        like_op = @controller.class.search_ilike ? "ILIKE" : "LIKE"
        return data.where(
          fields.map { |f|
            "CAST(#{conn.quote_column_name(f)} AS #{data_type}) #{like_op} ?"
          }.join(" OR "),
          *([ "%#{ActiveRecord::Base.sanitize_sql_like(search)}%" ] * fields.length),
        )
      end
    end

    data
  end
end

# Alias for convenience.
RESTFramework::SearchFilter = RESTFramework::Filters::SearchFilter
