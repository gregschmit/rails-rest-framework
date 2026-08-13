# Serializers

Serializers convert ActiveRecord objects (records and relations) into Ruby primitives
(`Array` / `Hash`), which the framework then renders as JSON, XML, or HTML. If you've configured
`fields` well (see [Fields](../03_controllers/#fields) in the Controllers
section), the default serializer will produce exactly what you want — no serializer class
needed.

## When You Need a Serializer Configuration

Reach for a serializer configuration when:

- You want to customize what's returned for nested associations.
- You want different fields on `index` vs. `show` (or list vs. single).
- You want to expose methods that would otherwise be too expensive to include for every record in
  a collection.
- You want to override the selection the framework derived from `fields`.

For most read-only adjustments, simply declaring `fields` and using `hidden` / `hidden_from_index`
in a field's `config` is enough. The sections below cover the more advanced cases.

## `NativeSerializer`

The default serializer uses Rails' built-in `ActiveModel::Serialization#serializable_hash`
under the hood. Its config is the same hash you would pass to `serializable_hash`:

```ruby
{
  only: [ :id, :name ],
  methods: [ :net_worth ],
  include: {
    cast_members: { only: [ :id, :name ], methods: [ :net_worth ] },
  },
}
```

You can configure the serializer in two ways, in order of precedence:

1. By writing a `NativeSerializer` subclass and pointing `serializer_class` at it.
2. Implicitly — by leaving serializer config blank and just using `fields`.

### Serializer Class

Define a subclass of `RESTFramework::NativeSerializer` when you want to shape output beyond what
`fields` gives you — different config per single/collection response, reuse across controllers, or
cleanly nested serializers:

```ruby
class CastMemberSerializer < RESTFramework::NativeSerializer
  self.config = { only: [ :id, :name ], methods: [ :net_worth ] }
  self.plural_config = { only: [ :id, :name ] }
end

class MovieSerializer < RESTFramework::NativeSerializer
  self.config = {
    only: [ :id, :name ],
    include: { cast_members: CastMemberSerializer.new(many: true) },
  }
  self.singular_config = {
    only: [ :id, :name ],
    methods: [ :active, :some_expensive_computed_property ],
    include: { cast_members: CastMemberSerializer.new(many: true) },
  }
end

class Api::MoviesController < ApiController
  self.model = Movie
  self.serializer_class = MovieSerializer
end
```

A `NativeSerializer` subclass exposes four class-level config attributes:

| Attribute         | Purpose                                                                      |
| ----------------- | ---------------------------------------------------------------------------- |
| `config`          | Default config; used when nothing else matches.                              |
| `singular_config` | Used when serializing a single record (explicitly or detected).              |
| `plural_config`   | Used when serializing a collection (explicitly or detected).                 |
| `action_config`   | Hash keyed by action name (e.g., `:index`, `:show`), takes highest priority. |

The serializer detects whether it's dealing with a single record or a collection based on the
object it's given (unless `many: true` / `many: false` is passed explicitly).

### Action-Specific Config

Use `action_config` to vary by controller action without using query params or branches:

```ruby
class MovieSerializer < RESTFramework::NativeSerializer
  self.action_config = {
    index: { only: [ :id, :name ] },
    show:  { only: [ :id, :name, :summary, :release_date ], methods: [ :ratings ] },
  }
end
```

Note: `index` falls back to `list` in `action_config` if `index` isn't defined.

## Query-Parameter Field Selection

Regardless of how the serializer is configured, clients can narrow the output at request time
using these query parameters:

| Query Param          | Default Name           | Purpose                                              |
| -------------------- | ---------------------- | ---------------------------------------------------- |
| `only`               | `"only"`               | Restrict serialization to these fields.              |
| `except`             | `"except"`             | Omit these fields from the default set.              |
| `include`            | `"include"`            | Opt into `hidden` fields.                            |
| `exclude`            | `"exclude"`            | Alias for `except`.                                  |

Each of these names is configurable via
`native_serializer_{only,except,include,exclude}_query_param` on the controller (set to `nil` to
disable any of them).

The allowed field set is always bounded by the controller's `fields` — clients can narrow it but
can't expand beyond what the controller declares.

## Serializing Associations Efficiently

### `association_limit`

By default, `has_many` / `has_and_belongs_to_many` associations are capped at `association_limit`
(10) records each, so responses are bounded out of the box. Adjust it on the controller (set to
`nil` to serialize all associated records):

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  propagate do
    self.association_limit = 20
  end
end
```

When a limit is set, the framework stops using `includes` (which would eager-load all rows) and
instead fires a per-record query with a `.limit(n)` applied. This is a tradeoff between N+1 queries
vs. loading unbounded data — use it only when associations can be large.

Clients can raise the limit for individual associations when the controller opts into
`enable_association_queries` — see
[Consumer-Requested Association Fields](../03_controllers/#consumer-requested-association-fields).

### `include_association_count`

When `true`, the serializer adds a `<assoc>.count` field alongside each collection association,
exposing how many records exist (independent of any limit applied):

```ruby
self.include_association_count = true
```

Be aware that this triggers a `COUNT` query per record per association.

## Integrations

### Action Text

When the controller has `enable_action_text = true`, `has_rich_text` fields appear in the default
serialization as their plain-text (`to_s`) representation.

### Active Storage

When the controller has `enable_active_storage = true`, attached files are serialized as:

```json
{ "filename": "poster.png", "signed_id": "...", "url": "..." }
```

`has_many_attached` serializes as an array of those hashes.

## Using ActiveModel::Serializer

If your project uses the `active_model_serializers` gem, `serializer_class` can point at an AMS
class directly. The framework wraps it in an adapter that makes it compatible with the rest of the
pipeline:

```ruby
class Api::UsersController < ApiController
  self.model = User
  self.serializer_class = UserSerializer   # < ActiveModel::Serializer
end
```

Because AMS adapters can produce unexpected output (`[]` becomes `{"":[]}`, for example), the
framework sets `adapter: nil` by default. You can override this by passing `adapter:` when
calling `render(api: ...)`.

## Response Rendering

Under the hood, the `api:` renderer (and the `render_api` helper) takes care of:

- Calling the configured serializer on records and relations.
- Negotiating between `json`, `xml`, and `html` formats (the browsable API).
- Falling back to `rescue_unknown_format_with` (default `:json`) for unknown formats.
- Rendering an appropriate `204 No Content` when the payload is an empty string (e.g., after
  `destroy`).

You can pass `html_kwargs: { ... }`, `json_kwargs: { ... }`, or `xml_kwargs: { ... }` to
`render_api` to specialize per format, and any other kwargs are forwarded to the underlying
`render` calls.

## Disabling JSON or XML

Turn off a format entirely at the controller level:

```ruby
class Api::InternalController < ApiController
  self.serialize_to_xml = false   # Never respond with XML.
end
```

With both `serialize_to_json` and `serialize_to_xml` set to `false`, only the HTML browsable API
remains.
