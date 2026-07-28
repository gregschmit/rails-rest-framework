# Performance

REST Framework tries to have reasonable defaults, but a few knobs are worth turning
deliberately in production. This section collects the performance-relevant settings from across
the other sections into one place, with guidance on when to use each.

## Limit Serialized Associations

Collection associations (`has_many`, `has_and_belongs_to_many`) are serialized fully by default,
which can blow up response size and query time for records with many associations. Set
`native_serializer_associations_limit` to cap it:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller
  self.native_serializer_associations_limit = 10
end
```

Clients can raise or lower this per request via the `associations_limit` query parameter, up to the
server-side cap. When a limit is set, the framework stops eager-loading via `includes` (as
`includes` would load every row regardless of limit) and instead issues a per-record query with
`.limit(n)`. This trades the eager-load optimization for a guarantee of bounded response size — use
it only for associations that really can be large.

If you need an accurate total as well as a bounded preview, enable:

```ruby
self.native_serializer_include_associations_count = true
```

This adds a `<assoc>.count` field to each record. Note that this triggers a `COUNT(*)` per record
per association — it's convenient but not free. For large collections, prefer a single
"totals" extra action over per-record counts.

## Watch N+1 Queries

For associations rendered without a limit, the framework uses `includes(...)` to eager-load them.
Combined with filter backends that may also add `includes`, most N+1s are avoided
automatically. That said:

- Methods in `fields` (not associations) that themselves load records *will* cause N+1s. The
  framework has no way to detect this.
- Use the [Bullet](https://github.com/flyerhzm/bullet) gem during development to catch any remaining
  N+1s.
- For methods that load expensive data, consider serializing via a custom serializer method or
  marking them `hidden_from_index` so they only run on `show`.

## Use Whitelists on User-Facing Filter Parameters

`QueryFilter`, `OrderingFilter`, and `SearchFilter` default to operating over every field in
`fields`. For internal administrative APIs this is fine. For public APIs, narrow the attack
surface:

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.fields = [ :id, :name, :release_date, :internal_notes, :director ]

  # Only these fields can be filtered, ordered, or searched by clients.
  self.filter_fields   = [ :name, :release_date, :director ]
  self.ordering_fields = [ :name, :release_date ]
  self.search_fields   = [ :name ]
end
```

Why this matters:

- Each filter clause adds SQL. Leaving every field filterable lets a client construct expensive
  queries (e.g., `?internal_notes_cont=...` on a non-indexed `TEXT` column).
- Ordering by non-indexed columns is a common DoS vector.
- `SearchFilter` uses `LIKE '%...%'` which can't use a normal index — constrain it to columns
  you've explicitly indexed (e.g., with a `gin` or `pg_trgm` index on PostgreSQL).

## Always Paginate Large Collections

An unpaginated `index` on a large table is a classic production bug. Configure a paginator at
the top of the inheritance hierarchy:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 30
  self.max_page_size = 100   # Prevent `?page_size=1000000` DoS.
end
```

Setting `max_page_size` also disables the `?page_size=0` "unpaginated" escape hatch — worth the
tradeoff in production for APIs where no client should be able to dump the full table.

## Skip Default Fields for Large Reverse Associations

Some `has_many` associations point at tables with millions of rows (audit logs, events, page
views). Exposing them as default fields makes default serialization catastrophically expensive.
Register them globally so they're excluded from the defaults:

```ruby
# config/initializers/rest_framework.rb
RESTFramework.configure do |config|
  config.large_reverse_association_tables = %w[ events audit_logs page_views ]
end
```

You can still opt a specific controller in by listing the field in `fields`.

## Exclude Associations Entirely

For controllers that don't need associations in the default field set, opt out:

```ruby
class Api::AdminStatsController < ApiController
  self.model = AuditEvent
  self.exclude_associations = true
end
```

This is roughly equivalent to `self.fields = Model.column_names - foreign_keys`, but keeps the
field set in sync with the schema automatically.

## Don't Rely on `filter_recordset_before_find = false`

Setting `filter_recordset_before_find = false` skips filter application when looking up single
records (`show`, `update`, `destroy`). That avoids a small amount of filter work but also means
records hidden by filters become accessible via direct ID lookup — which is usually a bug, not
a feature. Default (`true`) is almost always what you want.

## Disable Unused Response Formats

If your API doesn't need XML (many don't), turn it off:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller
  self.serialize_to_xml = false
end
```

The framework skips the XML render path entirely, saving a small amount of work per request.
Similarly, `serialize_to_json = false` disables JSON.

## Turn Off the Browsable API for Internal Services

If you have a service-to-service API that no human will ever browse:

```ruby
class Api::InternalController < ApiController
  self.rescue_unknown_format_with = nil

  before_action do
    head(:not_acceptable) and return if request.format.html?
  end
end
```

This avoids rendering the full HTML layout, and prevents the API from honoring `Accept:
text/html`.

## Vendor Browsable API Assets When Needed

By default the browsable API loads Bootstrap, highlight.js, Trix, and friends from public CDNs
with SRI integrity. If your deploys are air-gapped or behind strict CSP, serve the assets
yourself:

```ruby
RESTFramework.configure do |config|
  config.use_vendored_assets = true
end
```

Requires Propshaft (default on Rails 8+) or Sprockets. The vendored files ship with the gem.

## Reduce Error-Response Overhead

In production, make sure `show_backtrace` is `false` (it is by default, unless
`Rails.env.development?`):

```ruby
config.show_backtrace = false
```

With this off, error responses skip the backtrace formatting work and don't leak internals.

## Cache the OpenAPI Document

The OpenAPI document is computed from live reflections, which isn't cheap. If many clients
fetch it, consider caching with HTTP caching headers:

```ruby
class Api::MoviesController < ApiController
  def options
    expires_in(5.minutes, public: true)
    super
  end
end
```

Or, for a long-lived public document, serve a snapshotted version from a separate endpoint
(see the [OpenAPI section](../09_openapi/#consuming-the-document)).

## Production Checklist

A short list for going to production:

- [ ] `RESTFramework.config.show_backtrace = false`
- [ ] `RESTFramework.config.large_reverse_association_tables` set for expensive tables
- [ ] `paginator_class` set at the root, with `max_page_size` configured
- [ ] `filter_fields`, `ordering_fields`, and `search_fields` whitelisted for public APIs
- [ ] `native_serializer_associations_limit` set if any controller exposes large collection
      associations
- [ ] Bullet or equivalent run in CI to catch N+1s
- [ ] `serialize_to_xml = false` if you don't serve XML
- [ ] `use_vendored_assets = true` if you can't reach public CDNs
- [ ] Authentication and authorization set up at the root (see [Auth](../07_auth/))
- [ ] Error rescues cover any app-specific exceptions you want surfaced to the API
