# A simple paginator based on page numbers.
#
# Example: http://example.com/api/users/?page=3&page_size=50
class RESTFramework::Paginators::PageNumberPaginator < RESTFramework::Paginators::BasePaginator
  def initialize(**kwargs)
    super
    # Exclude any `select` clauses since that would cause `count` to fail with a SQL `SyntaxError`.
    @count = @data.except(:select).count
    @page_size = self._page_size

    @total_pages = @count / @page_size
    @total_pages += 1 if @count % @page_size != 0
  end

  def _page_size
    page_size = nil

    # Get from context, if allowed.
    if @controller.page_size_query_param
      if page_size = @controller.params[@controller.page_size_query_param].presence
        page_size = page_size.to_i
      end
    end

    # Otherwise, get from config.
    if !page_size && @controller.page_size
      page_size = @controller.page_size
    end

    # Ensure we don't exceed the max page size.
    if @controller.max_page_size && page_size > @controller.max_page_size
      page_size = @controller.max_page_size
    end

    # Ensure we return at least 1.
    return page_size.zero? ? 1 : page_size
  end

  # Get the page and return it so the caller can serialize it.
  def get_page(page_number=nil)
    # If page number isn't provided, infer from the params or use 1 as a fallback value.
    unless page_number
      page_number = @controller&.params&.[](@controller.page_query_param&.to_sym)
      if page_number.blank?
        page_number = 1
      else
        page_number = page_number.to_i
        if page_number.zero?
          page_number = 1
        end
      end
    end
    @page_number = page_number

    # Get the data page and return it so the caller can serialize the data in the proper format.
    page_index = @page_number - 1
    return @data.limit(@page_size).offset(page_index * @page_size)
  end

  # Wrap the serialized page with appropriate metadata. TODO: include links.
  def get_paginated_response(serialized_page)
    return {
      count: @count,
      page: @page_number,
      page_size: @page_size,
      total_pages: @total_pages,
      results: serialized_page,
    }
  end
end

# Alias for convenience.
RESTFramework::PageNumberPaginator = RESTFramework::Paginators::PageNumberPaginator
