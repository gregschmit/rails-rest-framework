module RESTFramework

  # A simple paginator based on page numbers.
  #
  # Example: http://example.com/api/users/?page=3&page_size=50
  class PageNumberPaginator
    def initialize(data:, controller:, **kwargs)
      @data = data
      @controller = controller
      @count = data.count
      @page_size = self._page_size

      @total_pages = @count / @page_size
      @total_pages += 1 if (@count % @page_size != 0)
    end

    def _page_size
      page_size = nil

      # Get from context, if allowed.
      if @controller.class.page_size_query_param
        if page_size = @controller.params[@controller.class.page_size_query_param].presence
          page_size = page_size.to_i
        end
      end

      # Otherwise, get from config.
      if !page_size && @controller.class.page_size
        page_size = @controller.class.page_size
      end

      # Ensure we don't exceed the max page size.
      if @controller.class.max_page_size && page_size > @controller.class.max_page_size
        page_size = @controller.class.max_page_size
      end

      # Ensure we return at least 1.
      return page_size.zero? ? 1 : page_size
    end

    def _page_query_param
      return @controller.class.page_query_param&.to_sym
    end

    def get_page(page_number=nil)
      # If page number isn't provided, infer from the params or use 1 as a fallback value.
      if !page_number
        page_number = @controller&.params&.[](self._page_query_param)
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

    # Wrap the serialized page with appripriate metadata.
    def get_paginated_response(serialized_page)
      return {
        count: @count,
        page: @page_number,
        total_pages: @total_pages,
        results: serialized_page,
      }
    end
  end

  # TODO: implement this
  # class CountOffsetPaginator
  # end

end
