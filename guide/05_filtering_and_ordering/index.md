# Filtering and Ordering

While `recordset` and `get_recordset` let the controller decide which records to expose, clients
often need to narrow or reorder the returned set themselves. The framework handles this through a
pluggable list of **filter backends**, run in order against the recordset.

## Configuring Filter Backends

`filter_backends` is an ordered array of filter classes. The default pipeline is:

```ruby
self.filter_backends = [
  RESTFramework::QueryFilter,
  RESTFramework::OrderingFilter,
  RESTFramework::SearchFilter,
]
```

To add Ransack support, append `RESTFramework::RansackFilter`:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  propagate do
    self.filter_backends = [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
      RESTFramework::RansackFilter,
    ]
  end
end
```

You can also remove backends you don't want by setting `filter_backends` explicitly. Custom
backends must respond to `filter_data(data)` and accept a `controller:` kwarg in `new`.

## QueryFilter

`QueryFilter` turns query-string params into `where` clauses. For the request
`GET /api/movies?cool=true&genre=scifi`, it calls
`recordset.where(cool: "true", genre: "scifi")`.

### Predicates

You can append a predicate suffix to any field name to use a comparison other than equality:

| Suffix   | Meaning                                       | Example                          |
| -------- | --------------------------------------------- | -------------------------------- |
| `_lt`    | Less than                                     | `?year_lt=2000`                  |
| `_lte`   | Less than or equal                            | `?year_lte=2000`                 |
| `_gt`    | Greater than                                  | `?rating_gt=7.5`                 |
| `_gte`   | Greater than or equal                         | `?rating_gte=7.5`                |
| `_not`   | Not equal (translates to `where.not`)         | `?status_not=archived`           |
| `_in`    | In a comma-separated list                     | `?genre_in=scifi,drama`          |
| `_cont`  | SQL `LIKE '%value%'` (contains substring)     | `?name_cont=star`                |
| `_true`  | Field is `true`                               | N/A — use raw key in params      |
| `_false` | Field is `false`                              | N/A — use raw key in params      |
| `_null`  | Field is `NULL`                               | N/A — use raw key in params      |

Multiple predicates on the same field are combined correctly:

```text
GET /api/movies?year_gte=1990&year_lt=2000&genre_in=scifi,drama
```

### Filtering on Association Fields

If a field is an association, you can filter on any of its `fields` (see
[Fields](../03_controllers/#fields) in the Controllers section) using dot notation, optionally
with a predicate:

```text
GET /api/movies?director.name_cont=nolan
GET /api/movies?cast_members.id_in=1,2,3
```

When a sub-field filter is used, `QueryFilter` automatically adds `includes(:director)` (etc.) to
the relation to avoid N+1 queries.

### Restricting Filterable Fields

By default `QueryFilter` allows any field in `fields`. Set `filter_fields` to a narrower
whitelist:

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.fields = [ :id, :name, :release_date, :enabled, :internal_notes ]
  self.filter_fields = [ :id, :name, :release_date, :enabled ]
end
```

`QueryFilter` is included in `filter_backends` by default and requires no extra configuration.

## OrderingFilter

Clients can request a different sort order with the `ordering` query parameter:

```text
GET /api/movies?ordering=name
GET /api/movies?ordering=-name               # Descending
GET /api/movies?ordering=director,-name      # Multi-column sort
GET /api/movies?ordering=director.name       # Sub-field
```

### Configuration

| Attribute              | Default        | Purpose                                                       |
| ---------------------- | -------------- | ------------------------------------------------------------- |
| `ordering_query_param` | `"ordering"`   | The query parameter name. Set to `nil` to disable ordering.   |
| `ordering_fields`      | `nil` = `fields` | Whitelist of fields allowed to be ordered by.               |
| `ordering_no_reorder`  | `false`        | Use `.order(...)` instead of `.reorder(...)`.                 |

By default the filter uses `.reorder`, which clears any existing ordering on the recordset. Set
`ordering_no_reorder = true` to append to the recordset's existing order instead.

## SearchFilter

`SearchFilter` does a simple multi-column `LIKE` search against string columns:

```text
GET /api/movies?search=star
```

### Configuration

| Attribute            | Default     | Purpose                                                                      |
| -------------------- | ----------- | ---------------------------------------------------------------------------- |
| `search_query_param` | `"search"`  | The query parameter name.                                                    |
| `search_fields`      | `nil`       | Explicit list of fields to search. Falls back to default label-like columns. |
| `search_ilike`       | `false`     | Use `ILIKE` (case-insensitive) instead of `LIKE`. PostgreSQL only.           |

When `search_fields` is unset, `SearchFilter` searches any field in the controller's `fields`
that also matches `RESTFramework.config.search_columns` (by default: `name`, `label`, `login`,
`title`, `email`, `username`, `url`, `description`, `note`). So on most models, search just works
if you have any of those columns.

All searched values are cast to strings inside the query (`CAST(column AS VARCHAR)`), so you can
search numeric or date columns too. MySQL/Trilogy uses `CHAR` instead of `VARCHAR` automatically.

## RansackFilter

For more advanced filtering (joins, grouping, custom predicates), add
`RESTFramework::RansackFilter` to `filter_backends`. This requires the `ransack` gem.

```text
GET /api/movies?q[name_cont]=star&q[director_name_start]=chris
```

### Configuration

| Attribute                      | Default       | Purpose                                                        |
| ------------------------------ | ------------- | -------------------------------------------------------------- |
| `ransack_query_param`          | `"q"`         | Query parameter for the ransack hash.                          |
| `ransack_options`              | `nil`         | Hash passed through to `ransack(q, opts)`.                     |
| `ransack_distinct`             | `true`        | Default `distinct:` for `.result(distinct:)`.                  |
| `ransack_distinct_query_param` | `"distinct"`  | Query param that lets clients override `distinct` per request. |

Clients can override `distinct` per request with e.g. `?distinct=false`. You still need to
configure `ransackable_attributes` / `ransackable_associations` on your models — the framework
doesn't bypass Ransack's own safety controls.

## Custom Filter Backends

Any class implementing this minimal interface can be plugged into `filter_backends`:

```ruby
class MyFilter < RESTFramework::Filters::BaseFilter
  def initialize(controller:)
    @controller = controller
  end

  def filter_data(data)
    # Return a new (or the same) ActiveRecord::Relation.
    data.where(...)
  end
end
```

The framework iterates `filter_backends` in order, passing the result of each backend into the
next, so backends compose naturally (e.g., `QueryFilter` narrows, then `OrderingFilter` sorts,
then `SearchFilter` intersects).

## Filtering Applies to `show` Too

By default the framework filters the recordset before looking up a single record (via
`get_record`). This means that if a record would be filtered out of the list, it's also hidden
from `show`/`update`/`destroy` — your filters double as access control.

To disable this and always look up against the full recordset, set:

```ruby
self.filter_recordset_before_find = false
```
