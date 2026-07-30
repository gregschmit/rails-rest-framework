# Exercises `page_total_count = false`: the paginator skips the `COUNT(*)` query, so the response
# omits `count`/`total_pages` and derives `next`/`previous` by fetching one extra record.
class Api::Test::NoTotalCountController < Api::TestController
  self.model = User
  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 2
  self.max_page_size = 2
  self.page_total_count = false
end
