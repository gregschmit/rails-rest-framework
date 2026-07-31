class RESTFramework::Filters::SearchFilter < RESTFramework::Filters::BaseFilter
  def _get_fields
    # Always return a list of strings; `@controller.readable_columns` already does.
    @controller.class.search_fields&.map(&:to_s) || (
      @controller.readable_columns & RESTFramework.config.search_columns
    )
  end

  # Filter data according to the request query parameters.
  def filter_data(data)
    search = @controller.request.query_parameters[@controller.class.search_query_param]

    # Reject nested-hash inputs like `?search[evil]=x` (Rack parses these into a
    # Hash, which `sanitize_sql_like` can't accept).
    return data unless search.is_a?(String)

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
