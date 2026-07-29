# Pagination

For large result sets, the framework can wrap the `index` response in a pagination envelope. By
default `paginator_class` is `nil` (no pagination). Set it to a paginator class to enable:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  propagate do
    self.paginator_class = RESTFramework::PageNumberPaginator
    self.page_size = 30
  end
end
```

## PageNumberPaginator

A simple paginator keyed by a page number. Responses take this shape:

```json
{
  "count": 124,
  "page": 3,
  "page_size": 30,
  "total_pages": 5,
  "next": "https://example.com/api/movies?page=4",
  "previous": "https://example.com/api/movies?page=2",
  "results": [ {}, {} ]
}
```

### Configuration

| Attribute               | Default       | Purpose                                                                             |
| ----------------------- | ------------- | ----------------------------------------------------------------------------------- |
| `page_size`             | `20`          | Default number of records per page.                                                 |
| `page_query_param`      | `"page"`      | Query param for the requested page number.                                          |
| `page_size_query_param` | `"page_size"` | Query param that lets clients override the page size. Set to `nil` to forbid this.  |
| `max_page_size`         | `nil`         | Upper limit on the client-requested page size.                                      |

Example requests:

```text
GET /api/movies?page=2
GET /api/movies?page=2&page_size=10
```

### Disabling Pagination Per Request

When `page_size_query_param` is set and `max_page_size` is not, a client can disable pagination
for a single request by passing `page_size=0`:

```text
GET /api/movies?page_size=0
```

This returns the full (unpaginated) result set. If `max_page_size` is configured, pagination is
always enforced and this escape hatch is disabled — useful for preventing a client from
inadvertently requesting every record.

### Invalid or Missing Page Numbers

- `page` not provided → page 1.
- `page` not numeric or `0` → page 1.
- `page` past the last page → returns an empty `results` array (no error).

### Query Parameters Preserved in `next`/`previous`

The `next` and `previous` URLs in the response are built from the current request parameters, so
filters and ordering are preserved when paging. For example, paginating
`/api/movies?genre=scifi&ordering=-year` returns `next` URLs that keep `genre=scifi` and
`ordering=-year`.

## Turning Pagination Off for a Controller

Leave `paginator_class` unset (or set it to `nil`) to disable pagination. The `index` action
will return the full set of filtered records.
