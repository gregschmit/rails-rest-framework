# A simple paginator based on page numbers.
#
# Example: http://example.com/api/users/?page=3&page_size=50
class RESTFramework::Paginators::PageNumberPaginator < RESTFramework::Paginators::BasePaginator
  def initialize(**kwargs)
    super
    @page_size = self._page_size
    @total_count = @controller.class.page_total_count

    # Compute the total count (and total pages) unless disabled. On large tables `page_total_count`
    # can be set to `false` to skip this `COUNT(*)` over the whole filtered set; `next` is then
    # derived by fetching one extra record in `get_page`.
    if @total_count
      # Exclude any `select` clauses, since that would cause `count` to fail with a SQL
      # `SyntaxError`.
      @count = @data.except(:select).count
      @total_pages = @count / @page_size
      @total_pages += 1 if @count % @page_size != 0
    end
  end

  def _page_size
    page_size = nil

    # Get from query param, if allowed.
    if param = @controller.class.page_size_query_param
      if raw = @controller.request.query_parameters[param].presence
        parsed = raw.to_i
        page_size = parsed if parsed > 0
      end
    end

    # Fall back to the configured page size.
    page_size ||= @controller.class.page_size&.to_i || 1

    # Ensure we don't exceed the max page size.
    max_page_size = @controller.class.max_page_size
    if max_page_size && page_size > max_page_size
      page_size = max_page_size
    end

    # Ensure we return at least 1.
    [ page_size, 1 ].max
  end

  # Get the page and return it so the caller can serialize it.
  def get_page(page_number = nil)
    # If page number isn't provided, infer from the query params or use 1 as a fallback value.
    unless page_number
      page_number = @controller&.request&.query_parameters&.[](@controller.class.page_query_param)
      if page_number.blank?
        page_number = 1
      else
        page_number = page_number.to_i
        if page_number < 1
          page_number = 1
        end
      end
    end
    @page_number = page_number

    # Get the data page and return it so the caller can serialize the data in the proper format.
    page_index = @page_number - 1
    offset = page_index * @page_size

    # Without a total count we can't derive `next` from `total_pages`, so detect whether a further
    # page exists with a cheap existence check (a `LIMIT 1` past this page) instead of a full count.
    unless @total_count
      @has_next = @data.except(:select).offset(offset + @page_size).exists?
    end

    @data.limit(@page_size).offset(offset)
  end

  # Wrap the serialized page with appropriate metadata.
  def get_paginated_response(serialized_page)
    page_query_param = @controller.class.page_query_param
    request = @controller.request
    base_params = request.query_parameters.symbolize_keys

    # Anchor next/previous to the request's own scheme/host/port so they point back at the same
    # endpoint the client is using — even when the app's `default_url_options` host differs from the
    # request host (e.g. an API served on a subdomain), which `url_for` would otherwise emit.
    host_options = {
      only_path: false,
      protocol: request.protocol,
      host: request.host,
      port: request.optional_port,
    }

    has_next = @total_count ? @page_number < @total_pages : @has_next
    next_url = if has_next
      @controller.url_for({ **base_params, page_query_param => @page_number + 1, **host_options })
    end
    previous_url = if @page_number > 1
      @controller.url_for({ **base_params, page_query_param => @page_number - 1, **host_options })
    end

    {
      count: @count,
      page: @page_number,
      page_size: @page_size,
      total_pages: @total_pages,
      next: next_url,
      previous: previous_url,
      results: serialized_page,
    }.compact
  end
end

# Alias for convenience.
RESTFramework::PageNumberPaginator = RESTFramework::Paginators::PageNumberPaginator
