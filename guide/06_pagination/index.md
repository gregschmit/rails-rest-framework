# Pagination

For large result sets, the framework wraps the `index` response in a pagination envelope.
**Pagination is on by default**: `paginator_class` is `RESTFramework::PageNumberPaginator`,
`page_size` is `20`, and `max_page_size` is `40`, so responses are bounded out of the box. Override
any of these to customize:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  propagate do
    self.page_size = 30       # default page size
    self.max_page_size = 100  # ceiling on a client-supplied `page_size`
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
| `max_page_size`         | `40`          | Upper limit on the client-requested page size. Set to `nil` to remove the cap.      |
| `page_total_count`      | `true`        | Whether to run a `COUNT(*)` to report `count`/`total_pages`. Set to `false` on large tables to skip it. |

### Skipping the Total Count on Large Tables

Every paginated request runs a `COUNT(*)` over the whole filtered set to report `count` and
`total_pages`. On very large tables that count can dominate the request cost. Set
`page_total_count = false` to skip it:

```ruby
class Api::EventsController < ApiController
  self.model = Event         # a table with hundreds of millions of rows
  self.page_total_count = false
end
```

The response then omits `count` and `total_pages`, and `next` is derived from a cheap existence
check (a `LIMIT 1` past the current page) instead of the total count:

```json
{
  "page": 3,
  "page_size": 30,
  "next": "https://example.com/api/events?page=4",
  "previous": "https://example.com/api/events?page=2",
  "results": [ {}, {} ]
}
```

Example requests:

```text
GET /api/movies?page=2
GET /api/movies?page=2&page_size=10
```

### Disabling Pagination Per Request

When `page_size_query_param` is set and `max_page_size` is `nil`, a client can disable pagination
for a single request by passing `page_size=0`:

```text
GET /api/movies?page_size=0
```

This returns the full (unpaginated) result set. Because `max_page_size` defaults to `40`, this
escape hatch is **off by default** — pagination is always enforced, preventing a client from
inadvertently (or maliciously) requesting every record. Set `max_page_size = nil` to allow it.

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

Since pagination is on by default, set `paginator_class = nil` to disable it. The `index` action
will then return the full set of filtered records as a bare array.

```ruby
class Api::ReportController < ApiController
  self.paginator_class = nil
end
```
