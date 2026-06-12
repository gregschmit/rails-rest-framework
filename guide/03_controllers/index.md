# Controllers

This is the core of the REST Framework. Projects typically already have an existing controller
inheritance hierarchy, and different controllers which inherit from the same parent often need
different REST Framework behavior. For these reasons, the framework ships a single
`RESTFramework::Controller` module that you `include` into any controller you want to become a
REST API controller. Behavior is then configured via class attributes — most notably `model`,
`bulk`, `excluded_actions`, `fields`, and `field_config`.

> **Note:** Previous versions of the framework used a tree of mixins (`BaseControllerMixin`,
> `ModelControllerMixin`, `ReadOnlyModelControllerMixin`, `BulkModelControllerMixin`, and
> `ListModelMixin`/`ShowModelMixin`/`CreateModelMixin`/`UpdateModelMixin`/`DestroyModelMixin`).
> These still work but are deprecated and emit deprecation notices. The guide below only covers
> the new, recommended approach.

## The `Controller` Module

To transform any controller into a REST Framework controller, include the `Controller` module:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  # Configuration set here propagates to child controllers via Rails' `class_attribute`.
end
```

Including `Controller` by itself gives you a "base" controller — no CRUD actions are exposed, but
you get:

- The `api` renderer (and the `render_api` helper) that powers the browsable API.
- A default `root` action that renders a simple welcome message.
- Auto-rescue of common `ActiveRecord` and `ActionController` exceptions into JSON error responses.
- Support for `extra_actions` / `extra_member_actions` metadata-driven routing.
- Automatic CSRF skip (`skip_before_action :verify_authenticity_token`).

To turn a controller into a full CRUD controller, set `model` (and optionally `bulk`):

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.bulk = true
  self.fields = [ :id, :name, :release_date ]
end
```

Setting `model` is what enables the built-in `index`, `show`, `create`, `update`, and `destroy`
actions. Setting `bulk = true` additionally enables `create` bulk mode (array payloads to the
collection `POST`), `update_all`, and `destroy_all`.

> **Always set `model` explicitly.** The framework no longer tries to infer the model from the
> controller name. If `model` is nil, the controller simply won't respond to the built-in CRUD
> actions (you will get routing errors or "Unknown action" responses).

### Root Controller Pattern

It's typically best to dedicate a controller for the API root so that root-specific actions and
configuration don't propagate through inheritance to every resource controller. A common layout:

```text
app/controllers/
├── api/
│   ├── root_controller.rb
│   ├── movies_controller.rb
│   └── users_controller.rb
├── api_controller.rb
└── application_controller.rb
```

`ApiController` holds shared configuration (pagination, filters, etc.):

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 30
end
```

`Api::RootController` holds the API root action and anything else you want routed at `/api`:

```ruby
class Api::RootController < ApiController
  self.extra_actions = { test: :get }

  # `rest_root` routes this action to '/' within the `:api` namespace.
  def root
    render(api: {
      message: "Welcome to the API.",
      how_to_authenticate: "Use a Bearer token or the `api_key` query parameter.",
    })
  end

  def test
    render(api: { message: "Hello, world!" })
  end
end
```

## Response Rendering

A fundamental feature of the framework is the browsable API: HTML, JSON, and XML are all served
from the same endpoint, so developers can interact with the API in a browser while machines get a
lightweight JSON/XML response.

The framework provides an `api` renderer, which is a thin wrapper around the `render_api` method.

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller
  self.extra_actions = { test: :get }

  def test
    render(api: { message: "Test successful!" })
  end
end
```

`render_api` accepts a hash, a string, an `ActiveRecord::Base`, or an `ActiveRecord::Relation`.
When given a record or relation, it automatically runs it through the configured serializer.

> The historical `api_response` method still works but emits a deprecation warning — use
> `render_api` (or `render(api: ...)`) in new code.

### Format Fallback

If a request arrives with a format the controller doesn't serve, `render_api` falls back to the
`rescue_unknown_format_with` format (default: `:json`). Set this to `nil` to let
`ActionController::UnknownFormat` propagate.

## Extra Actions

Routing additional actions on the controller is done declaratively through `extra_actions` and
`extra_member_actions`. The resourceful routers automatically read these and wire up the routes.

### `extra_actions` (collection actions)

`extra_actions` defines collection-level actions as a hash of `endpoint => method(s)`.

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller
  self.extra_actions = { test: :get }

  def test
    render(api: { message: "Test successful!" })
  end
end
```

Multiple HTTP methods:

```ruby
self.extra_actions = { test: [ :get, :post ] }
```

Hash form for full control (custom path, multiple methods, metadata for OpenAPI):

```ruby
self.extra_actions = {
  test_action: {
    path: :test,          # Route `/test` to `test_action` (useful when the action name conflicts).
    methods: :get,
    metadata: {
      label: "Run Test",
      description: "Executes the test action.",
    },
  },
}
```

> `extra_collection_actions` is an alias for `extra_actions`.

### `extra_member_actions`

`extra_member_actions` defines actions that operate on a single record (requiring an `id` path
parameter). These only apply to resourceful routes.

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.extra_member_actions = { disable: :patch }

  def disable
    # `get_record` raises `ActiveRecord::RecordNotFound` on miss, which the framework rescues.
    record = self.get_record
    # `update!` raises on validation failure, which the framework also rescues.
    record.update!(enabled: false)
    render(api: record)
  end
end
```

### Delegating to Model Methods

If an extra action's `metadata[:delegate]` is `true` and the model responds to the action, the
framework auto-defines the controller action for you and forwards `params`:

```ruby
self.extra_actions = {
  archive_stale: { methods: :post, metadata: { delegate: true } },
}
```

This also works for `extra_member_actions`, where the record is the receiver.

## Resource Configuration

### `model`

The `model` attribute wires the controller up to an `ActiveRecord` model. This single attribute is
what enables built-in CRUD behavior — without it, the controller is a "base" controller with no
default actions.

```ruby
class Api::CoolMoviesController < ApiController
  self.model = Movie
end
```

### `recordset`

`recordset` statically limits the set of records the controller operates on. It can be any
`ActiveRecord::Relation`.

```ruby
class Api::CoolMoviesController < ApiController
  self.model = Movie
  self.recordset = Movie.where(cool: true).order(id: :asc)
end
```

For dynamic recordsets (e.g., scoped to `current_user`), override `get_recordset` on the instance:

```ruby
class Api::CoolMoviesController < ApiController
  self.model = Movie

  def get_recordset
    Movie.where(owner: current_user).order(id: :asc)
  end
end
```

Always set `model` explicitly when overriding `get_recordset`, since the framework uses `model`
(not the recordset) for things like fields, strong params, and the OpenAPI schema.

### `bulk` — Bulk Actions

Setting `self.bulk = true` enables three additional behaviors:

- `POST /resource` with a JSON array body creates multiple records in one transaction.
- `PATCH`/`PUT /resource` (routed as `update_all`) updates multiple records in one transaction.
- `DELETE /resource` (routed as `destroy_all`) destroys multiple records in one transaction.

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.bulk = true
end
```

Update payload format (array of records keyed by primary key):

```json
[
  { "id": 1, "name": "Updated Name" },
  { "id": 2, "enabled": false }
]
```

Destroy payload format (array of primary keys):

```json
[ 1, 2, 3 ]
```

Bulk responses include a per-record `errors` key so clients can detect partial failures. Note that
all bulk operations run inside a single database transaction.

### `excluded_actions` — Disabling Built-in Actions

`excluded_actions` is an array of action names to exclude from routing. Use this to trim down a
CRUD controller (for example, to make it read-only) without giving up the framework's behavior for
the remaining actions.

```ruby
class Api::ReadOnlyMoviesController < ApiController
  self.model = Movie
  self.excluded_actions = [ :create, :update, :destroy, :update_all, :destroy_all ]
end
```

Valid values include the built-in REST actions (`:index`, `:show`, `:create`, `:update`,
`:destroy`) and, if `bulk` is enabled, the bulk actions (`:update_all`, `:destroy_all`). The
resourceful routers will skip routing excluded actions.

### `singleton_controller`

If set to `true`, the resourceful router will generate singular (`resource`) rather than plural
(`resources`) routes for this controller — meaning no `id` in the URL and no `index` action. You
can also force plural by setting it to `false`. When `nil` (the default), the router uses the
plurality implied by `rest_resource` vs `rest_resources`.

## Fields

`fields` and `field_config` decide:

- Which columns, associations, and methods appear in serialized output.
- Which parameters the API accepts in the request body (via strong parameters).
- Which fields are filterable, orderable, and searchable by default.
- What metadata the browsable API and the OpenAPI document advertise.

Setting `fields` thoughtfully will usually give you the API you want without further
configuration.

### The `fields` Attribute

**Default behavior (`nil`):** if `fields` is not set, it defaults to all columns plus all direct
associations of the model. Foreign-key columns (e.g., `user_id`) are dropped in favor of the
association itself (e.g., `user`). This is convenient for administrative APIs but is usually too
permissive for production-facing APIs — you should set `fields` explicitly for any API consumed
by third parties.

**Array form — explicit list:** set `fields` to an array of symbols or strings to list exactly
what the controller exposes:

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.fields = [ :id, :name, :release_date, :director ]
end
```

Any entry that isn't a column or association is assumed to be a model method. Methods are
automatically marked read-only.

**Hash form — relative to defaults:** set `fields` to a hash to adjust the default set without
listing every column:

```ruby
class Api::UsersController < ApiController
  self.model = User
  self.fields = {
    include: [ :calculated_popularity ],   # Add a method to the default set.
    exclude: [ :impersonation_token ],     # Remove something from the default set.
  }
end
```

Supported keys:

| Key       | Meaning                                                                              |
| --------- | ------------------------------------------------------------------------------------ |
| `only`    | Seed the list with just these entries (instead of the default columns/associations). |
| `include` | Add entries to the set (e.g., model methods, extra associations).                    |
| `exclude` | Remove entries from the set. Alias: `except`.                                        |

All four can be combined:

```ruby
self.fields = {
  only: Movie.column_names - [ "deleted_at" ],   # Start from just these columns.
  include: [ :director, :is_featured ],          # Then add these.
  exclude: [ :internal_notes ],                  # Then remove these.
}
```

Unknown keys emit a `Rails.logger.warn` at load time.

**Mixing columns, associations, and methods:** because the framework inspects the model, a single
`fields` list can mix all three:

```ruby
self.fields = [
  :id,                 # column
  :name,               # column
  :director,           # belongs_to association
  :cast_members,       # has_many association
  :is_featured,        # model method
]
```

- Columns are serialized as scalar values and included in strong params.
- Associations are serialized using their `sub_fields` (see below), and the association is
  translated into either `<foreign_key>` / `<name>_ids` (for id assignment) or
  `<name>_attributes` (for nested attributes) in strong params.
- Methods are read-only (never accepted in the request body), but their return values are
  serialized.

### Per-Field Configuration: `field_config`

`field_config` lets you override how a specific field behaves. It's a hash keyed by field name
whose values are option hashes:

```ruby
class Api::UsersController < ApiController
  self.model = User
  self.fields = [ :id, :name, :email, :password, :bio, :profile_picture ]
  self.field_config = {
    email: { label: "Email Address" },
    password: { write_only: true },                 # Never serialize back out.
    bio: { hidden_from_index: true },               # Skip on collection responses.
    profile_picture: { required: true },
  }
end
```

You only need to specify the keys you actually want to override — the framework fills in defaults
from the model's schema and validators.

**Recognized keys:**

| Key                          | Purpose                                                                                         |
| ---------------------------- | ----------------------------------------------------------------------------------------------- |
| `label`                      | Human-readable label (used in the browsable API and OpenAPI). Defaults to `titleize`d name.     |
| `read_only`                  | Exclude from request body strong params. Primary keys default to `read_only: true`.             |
| `write_only`                 | Exclude from serialization. Useful for secrets like `password`.                                 |
| `hidden`                     | Exclude from serialization unless the client opts in with the `include` or `only` query params. |
| `hidden_from_index`          | Exclude from collection (`index`) serialization. Still included in `show`.                      |
| `required`                   | Mark the field as required in metadata (inferred from `null: false` / presence validators).    |
| `default`                    | Default value (inferred from the schema).                                                       |
| `type`                       | The field's type (inferred from columns/attributes).                                            |
| `enum_variants`              | For enum columns, a map of value to database representation.                                    |
| `sub_fields`                 | For associations, the sub-fields to render/accept. See [Association Sub-Fields](#association-sub-fields). |
| `id_field`                   | For associations, the scalar id field (e.g., `user_id`, `tag_ids`).                             |
| `nested_attributes_options`  | Passed through for `accepts_nested_attributes_for` associations.                                |

Most of the other entries (`kind`, `primary_key`, `association_pk`, `validators`, `reflection`)
are filled in by the framework and surfaced through the browsable API and OpenAPI metadata. You
usually don't set these yourself, but you can read them from `field_configuration` if you're
building custom behavior.

### Global Field Defaults

Three global settings in `RESTFramework.config` provide sensible defaults that apply to every
controller:

```ruby
RESTFramework.configure do |config|
  config.read_only_fields  = %w[ created_at updated_at created_by_id updated_by_id ]
  config.write_only_fields = %w[ password password_confirmation ]
end
```

These can be overridden per-controller via the `read_only_fields` / `write_only_fields` class
attributes, or per-field via `read_only` / `write_only` keys in `field_config`.

### Hidden vs. `hidden_from_index` vs. `write_only`

- `hidden: true` — never serialized unless the client explicitly requests the field with `?only=`
  or `?include=`. Useful for expensive fields or PII a user must opt into.
- `hidden_from_index: true` — serialized on `show` and other member actions, but skipped on
  collection responses. Useful for long text fields or joins you don't want to pay for in lists.
- `write_only: true` — never serialized, but is still accepted in the request body. Useful for
  passwords and similar credentials. Implies `hidden`.

The controller-level `hidden_fields` attribute is a shortcut for setting `hidden: true` on a list
of fields without writing out a full `field_config`.

### Computing the Full Field Configuration

At runtime the framework merges `field_config` with data it infers from the model — columns,
attribute defaults, reflections, validators, primary-key info, enum variants, Action Text /
Active Storage reflections — into a single hash available as `field_configuration`:

```ruby
Api::MoviesController.field_configuration
# => {
#   "id" => { primary_key: true, read_only: true, kind: "column", type: :integer, label: "ID", ... },
#   "name" => { kind: "column", type: :string, required: true, validators: { presence: [{}] }, ... },
#   "director" => { kind: "association", sub_fields: ["id", "name"], id_field: "director_id", ... },
#   ...
# }
```

This hash drives the browsable API, the OpenAPI schema, strong parameters, and the filter/search
metadata. If you build any custom behavior, consult `field_configuration` rather than
re-deriving field info from the model.

### Association Sub-Fields

When a field is an association, the framework automatically picks a set of `sub_fields` — by
default, the primary key plus the first "label-like" column that exists (from
`RESTFramework.config.label_fields`: `name`, `label`, `login`, `title`, `email`, `username`,
`url`).

You can override the sub-fields for any association via `field_config`:

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.fields = [ :id, :name, :director, :cast_members ]
  self.field_config = {
    director: { sub_fields: [ :id, :name, :date_of_birth ] },
    cast_members: { sub_fields: [ :id, :name, :net_worth ] },
  }
end
```

Sub-fields participate in:

- Serialization (nested associations use them by default).
- Filtering (e.g., `?director.name_cont=chris`).
- Ordering (e.g., `?ordering=director.name`).

### Association Assignment

For each association field, the framework exposes **either** id assignment **or** nested
attributes assignment in strong params:

- **Id assignment:** scalars are accepted under the reflection's foreign key (`belongs_to`) or
  singularized + `_ids` (`has_many` / `has_and_belongs_to_many`). Controlled by
  `permit_id_assignment` (default `true`).
- **Nested attributes:** hashes are accepted under `<assoc>_attributes`, with the same
  `sub_fields` plus `_destroy`. Controlled by `permit_nested_attributes_assignment` (default
  `true`). Requires `accepts_nested_attributes_for` on the model.

At request time, the framework inspects the payload: arrays/hashes-of-hashes are treated as
nested attributes, and scalars/arrays-of-scalars are treated as id assignment. Your API consumers
can send **either** form under the association name directly — the framework dispatches.

### Action Text and Active Storage

With `enable_action_text = true`, the framework includes `has_rich_text` attributes in the
default fields list (as their unprefixed names — e.g., `content` for a `has_rich_text :content`).
`field_configuration` marks them as `kind: "rich_text"`, they are serialized as their `to_s`
(plain text) representation, and they are accepted as scalars in the request body.

With `enable_active_storage = true`, the framework includes `has_one_attached` and
`has_many_attached` fields. `field_configuration` marks them as `kind: "attachment"` with
`attachment_type` of `:has_one_attached` or `:has_many_attached`. Uploads can arrive as:

- A regular multipart upload.
- An ActiveStorage-style hash: `{ io:, content_type:, filename:, identify:, key: }`.
- A base64 data URL (`data:image/png;base64,...`), which the framework decodes and converts to
  the ActiveStorage hash form automatically.
- An array of any of the above for `has_many_attached` — including arrays that mix existing
  `signed_id` strings (to keep attachments) with new hashes (to add attachments).

### `exclude_associations`

If you want the default `fields` to include columns only (and not associations), set
`exclude_associations = true`:

```ruby
class Api::AdminStatsController < ApiController
  self.model = AuditEvent
  self.exclude_associations = true
end
```

This is also honored when `fields` is given as a hash, since the hash form derives its default
set from the model the same way.

### Per-Request Fields

For per-request logic, override the instance method `get_fields`:

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.fields = [ :id, :name, :release_date ]

  def get_fields
    fields = super
    fields += [ :internal_notes ] if current_user.admin?
    fields
  end
end
```

Clients can also narrow the serialized field set at request time through query parameters:

- `?only=id,name` — restrict serialization to these fields (subject to `fields`).
- `?except=release_date` — omit these fields.
- `?include=bio` — opt into a `hidden` field.
- `?exclude=bio` — alias for `except`.

The query parameter names are all configurable (`native_serializer_*_query_param`). The
class-level `fields` list still acts as the outer bound — clients can narrow the set, but they
cannot expand it beyond what the controller declares.

### Complete Example

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.bulk = true

  self.fields = {
    only: [ :id, :name, :release_date, :summary, :enabled ],
    include: [ :director, :cast_members, :is_featured, :poster ],
  }

  self.field_config = {
    name:         { required: true, label: "Title" },
    summary:      { hidden_from_index: true },
    director:     { sub_fields: [ :id, :name, :date_of_birth ] },
    cast_members: { sub_fields: [ :id, :name, :net_worth ] },
    is_featured:  { read_only: true },
    poster:       { required: true },
  }

  self.read_only_fields = [ :id, :created_at, :updated_at ]

  self.enable_active_storage = true
end
```

With this configuration:

- `GET /api/movies` returns `id`, `name`, `release_date`, `enabled`, `director`, `cast_members`,
  `is_featured`, and `poster` — `summary` is omitted (`hidden_from_index`).
- `GET /api/movies/:id` returns the same plus `summary`.
- `POST /api/movies` accepts `name`, `release_date`, `summary`, `enabled`, `director` (as either
  `director_id` or `director_attributes`), `cast_members` (as either `cast_member_ids` or
  `cast_members_attributes`), and `poster` (as a multipart upload or base64 string).
  `is_featured` is rejected because it's marked `read_only`.
- `POST /api/movies` with a JSON array performs a bulk create in a transaction (because
  `bulk = true`).
- Filters default to the declared fields — e.g., `?director.name_cont=nolan` works out of the
  box.

## Finding Records

The built-in `show`, `update`, and `destroy` actions call `get_record`, which looks up by primary
key by default. You can optionally allow look-ups by other fields using a query parameter.

### `find_by_query_param` and `find_by_fields`

```ruby
class Api::UsersController < ApiController
  self.model = User
  self.find_by_fields = [ :username, :email ]   # nil = allow any column via the query param
  self.find_by_query_param = "find_by"          # default: "find_by"; nil disables this feature
end
```

Example: `GET /api/users/alice?find_by=username` looks up by `username` instead of `id`.

### `filter_recordset_before_find`

When `true` (the default), filter backends run before `find`, so lookups respect the same
filtering logic as list actions. Set to `false` to always look up against the full recordset.

## Request Body Handling

### `allowed_parameters`

By default, the framework generates strong parameters for you based on `fields`, handling
association `_id` / `_ids` variations and `_attributes` for `accepts_nested_attributes_for`.

To override this, set `allowed_parameters` to an array of scalar field names, a hash for nested
permits, or `true` to permit everything.

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.allowed_parameters = [ :name, { tag_ids: [] } ]
end
```

For different create vs update permits, override `get_create_params` / `get_update_params`.

### `create_from_recordset`

When `true` (the default), new records are created from the filtered recordset, meaning any
conditions on the recordset (e.g., `Movie.where(cool: true)`) are inherited as defaults on the new
record. When `false`, records are created directly from the model, bypassing the recordset.

```ruby
class Api::CoolMoviesController < ApiController
  self.model = Movie
  self.fields = [ :id, :name ]       # `cool` is read-only — not in the allowed params.

  def get_recordset
    Movie.where(cool: true)
  end
end
```

`POST` with `{ "name": "Superman" }` creates a record with `cool: true` inherited from the
recordset.

### Association Assignment

The framework inspects the body at request time and dynamically dispatches association payloads to
the correct ActiveRecord API:

- A hash or array of hashes under an association key gets promoted to `<assoc>_attributes`
  (requires `accepts_nested_attributes_for` on the model).
- A scalar or array of scalars gets promoted to `<foreign_key>` / `<singularized>_ids`.

These can be controlled per-controller with `permit_id_assignment` and
`permit_nested_attributes_assignment` (both `true` by default).

## Configuration Reference

The class attributes below all have sensible defaults and can be set at any level of the
inheritance hierarchy (child controllers inherit from parents). Grouped by concern:

### Core / Resource

| Attribute                    | Default | Purpose                                                                                  |
| ---------------------------- | ------- | ---------------------------------------------------------------------------------------- |
| `model`                      | `nil`   | The `ActiveRecord` model. Required for built-in CRUD behavior.                           |
| `recordset`                  | `nil`   | Static recordset. Falls back to `model.all`.                                             |
| `bulk`                       | `false` | Enables bulk `create`, `update_all`, and `destroy_all` actions.                          |
| `excluded_actions`           | `nil`   | Array of built-in actions to skip routing.                                               |
| `singleton_controller`       | `nil`   | Force singular/plural resourceful routing.                                               |
| `extra_actions`              | `nil`   | Hash of extra collection actions.                                                        |
| `extra_member_actions`       | `nil`   | Hash of extra member actions.                                                            |
| `create_from_recordset`      | `true`  | Create new records through the recordset (inherit recordset conditions as defaults).     |

### Fields

| Attribute                  | Default  | Purpose                                                                                   |
| -------------------------- | -------- | ----------------------------------------------------------------------------------------- |
| `fields`                   | `nil`    | Fields exposed by the controller. `nil` means all columns + associations.                 |
| `field_config`             | `nil`    | Per-field overrides (`read_only`, `hidden`, `label`, etc.). See [Fields](#fields).        |
| `read_only_fields`         | (global) | Fields treated as read-only (excluded from allowed params).                               |
| `write_only_fields`        | (global) | Fields treated as write-only (excluded from serialization).                               |
| `hidden_fields`            | `nil`    | Fields excluded from serialization unless explicitly requested via the query params.      |
| `exclude_associations`     | `false`  | Omit associations from the default `fields` set.                                          |
| `find_by_fields`           | `nil`    | Whitelist of fields usable for record lookup via `find_by_query_param`.                   |
| `find_by_query_param`      | `"find_by"` | Query parameter name for alternate-field lookup. Set to `nil` to disable.              |

### Metadata / Display

| Attribute              | Default   | Purpose                                                               |
| ---------------------- | --------- | --------------------------------------------------------------------- |
| `title`                | inferred  | Controller title shown in the browsable API and OpenAPI document.     |
| `description`          | `nil`     | Description shown in the browsable API and OpenAPI document.          |
| `version`              | `nil`     | API version string shown in the OpenAPI document.                     |
| `inflect_acronyms`     | (global)  | Acronyms the titleizer should preserve (e.g., `"API"`, `"ID"`).       |
| `openapi_include_children` | `false` | Include descendant controllers in this controller's OpenAPI schema. |

### Request / Response

| Attribute                      | Default  | Purpose                                                                                                           |
| ------------------------------ | -------- | ----------------------------------------------------------------------------------------------------------------- |
| `allowed_parameters`           | `nil`    | Strong parameters override. `nil` = derived from `fields`. `true` = permit all.                                   |
| `permit_id_assignment`         | `true`   | Permit `<foreign_key>` / `<name>_ids` for associations.                                                           |
| `permit_nested_attributes_assignment` | `true` | Permit `<assoc>_attributes` for `accepts_nested_attributes_for` associations.                                |
| `rescue_unknown_format_with`   | `:json`  | Format to fall back to for unknown request formats.                                                               |
| `serializer_class`             | `nil`    | Explicit serializer class. Defaults to `NativeSerializer`.                                                        |
| `serialize_to_json`            | `true`   | Render a JSON response format.                                                                                    |
| `serialize_to_xml`             | `true`   | Render an XML response format.                                                                                    |
| `disable_adapters_by_default`  | `true`   | Disable AMS adapters by default (avoids `{"":[]}` on empty arrays).                                               |

### Filtering, Ordering, Searching

See the [Filtering and Ordering](../05_filtering_and_ordering/) section for details.

| Attribute                        | Default                                                  | Purpose                                    |
| -------------------------------- | -------------------------------------------------------- | ------------------------------------------ |
| `filter_backends`                | `[QueryFilter, OrderingFilter, SearchFilter]`            | Ordered list of filter backends.           |
| `filter_recordset_before_find`   | `true`                                                   | Apply filters before `get_record` lookup.  |
| `filter_fields`                  | `nil`                                                    | Whitelist for `QueryFilter` (defaults to `fields`). |
| `ordering_fields`                | `nil`                                                    | Whitelist for `OrderingFilter`.            |
| `ordering_query_param`           | `"ordering"`                                             | Query param for ordering.                  |
| `ordering_no_reorder`            | `false`                                                  | Use `order` instead of `reorder`.          |
| `search_fields`                  | `nil`                                                    | Fields searched by `SearchFilter`.         |
| `search_query_param`             | `"search"`                                               | Query param for search.                    |
| `search_ilike`                   | `false`                                                  | Use `ILIKE` (PostgreSQL) instead of `LIKE`. |
| `ransack_options`                | `nil`                                                    | Options passed to `ransack(q, opts)`.      |
| `ransack_query_param`            | `"q"`                                                    | Query param for Ransack.                   |
| `ransack_distinct`               | `true`                                                   | `distinct` default for Ransack results.    |
| `ransack_distinct_query_param`   | `"distinct"`                                             | Query param to override `distinct`.        |

### Serialization

See the [Serializers](../04_serializers/) section for full details.

| Attribute                                         | Default            | Purpose                                                                    |
| ------------------------------------------------- | ------------------ | -------------------------------------------------------------------------- |
| `native_serializer_config`                        | `nil`              | Default config for `NativeSerializer`.                                     |
| `native_serializer_singular_config`               | `nil`              | Config used for single-record responses.                                   |
| `native_serializer_plural_config`                 | `nil`              | Config used for collection responses.                                      |
| `native_serializer_only_query_param`              | `"only"`           | Query param to limit serialized fields.                                    |
| `native_serializer_except_query_param`            | `"except"`         | Query param to omit serialized fields.                                     |
| `native_serializer_include_query_param`           | `"include"`        | Query param to reveal `hidden` fields.                                     |
| `native_serializer_exclude_query_param`           | `"exclude"`        | Query param to exclude specific fields.                                    |
| `native_serializer_associations_limit`            | `5`                | Default limit on the number of records included per collection association. |
| `native_serializer_associations_limit_max`        | `5`                | Maximum value the query param can raise the limit to (`nil` disables the query param). |
| `native_serializer_associations_limit_query_param`| `"associations_limit"` | Query param to adjust the associations limit (up to `_max`).           |
| `native_serializer_include_associations_count`    | `false`            | Add a `<assoc>.count` field for each collection association.               |

### Pagination

See the [Pagination](../06_pagination/) section for details.

| Attribute                | Default  | Purpose                                                        |
| ------------------------ | -------- | -------------------------------------------------------------- |
| `paginator_class`        | `nil`    | Paginator class (e.g., `RESTFramework::PageNumberPaginator`).  |
| `page_size`              | `20`     | Default page size.                                             |
| `page_query_param`       | `"page"` | Query param for the page number.                               |
| `page_size_query_param`  | `"page_size"` | Query param for user-controlled page size. `nil` to disable. |
| `max_page_size`          | `nil`    | Upper limit on user-requested page size.                       |

### Integrations

| Attribute                | Default | Purpose                                                                     |
| ------------------------ | ------- | --------------------------------------------------------------------------- |
| `enable_action_text`     | `false` | Enable serialization of `has_rich_text` attributes as their plain text.     |
| `enable_active_storage`  | `false` | Enable serialization and upload support for `has_one_attached` / `has_many_attached` (including base64-encoded uploads). |

## Read-Only Controller Recipe

A common pattern — previously achieved by the `ReadOnlyModelControllerMixin`:

```ruby
class Api::ReadOnlyMoviesController < ApiController
  self.model = Movie
  self.excluded_actions = [ :create, :update, :destroy, :update_all, :destroy_all ]
end
```

## Bulk-Enabled Controller Recipe

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.bulk = true
  self.fields = [ :id, :name, :release_date, :enabled ]
  self.extra_member_actions = { first: :get }

  def first
    render(api: self.get_records.first!)
  end

  def get_recordset
    Movie.where(enabled: true)
  end
end
```

## Error Handling

The framework uses `rescue_from` to catch common Rails exceptions and renders an appropriate error
response. The full list can be found in `RESTFramework::Controller::RRF_RESCUED_RAILS_EXCEPTIONS`,
and includes things like `ActiveRecord::RecordNotFound` and `ActiveRecord::RecordInvalid`.

Error responses have the form:

```json
{
  "message": "Validation failed: Name can't be blank",
  "errors": { "name": [ "can't be blank" ] }
}
```

Because of this, your code can (and should) use exception-raising methods like `find`, `update!`,
and `destroy!` — the framework will turn the raised exceptions into clean API responses.

## Controller Finalization

The framework uses a `TracePoint` hook to automatically call `rrf_finalize` at the end of every
controller class definition. This is what sets up model delegation for `extra_actions` with
`metadata: { delegate: true }` and (optionally) freezes configuration.

If you set `RESTFramework.config.auto_finalize = false` for performance, call `rrf_finalize`
manually at the end of each controller class.

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  # ...
  rrf_finalize
end
```
