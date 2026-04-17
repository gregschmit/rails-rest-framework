# Global Configuration

Almost all REST Framework behavior is configured on individual controllers via class attributes,
because different APIs in the same codebase often need different behavior. A small set of
settings, however, are truly global — either because they're read at gem-load time, because they
affect things outside the controller pipeline, or because they provide the defaults that
controller-level attributes inherit from.

These live under `RESTFramework.config` and are set in an initializer:

```ruby
# config/initializers/rest_framework.rb
RESTFramework.configure do |config|
  config.show_backtrace = Rails.env.development? || Rails.env.test?
  config.read_only_fields = %w[ created_at updated_at created_by_id updated_by_id ]
  config.inflect_acronyms += %w[ URL HTML ]
end
```

This section enumerates every attribute on `RESTFramework::Config`, what it does, when it's
read, and when you should change it.

## Reference

### `show_backtrace`

- **Type:** Boolean
- **Default:** `Rails.env.development?`

When `true`, the framework's error responses include the full exception backtrace as an
`exception` key in the JSON payload. Useful for development; you almost certainly want this
`false` in production to avoid leaking internals.

The default is `Rails.env.development?` at the time `RESTFramework.config` is first read, so if
you want to override, do it explicitly:

```ruby
config.show_backtrace = Rails.env.development? || Rails.env.test?
```

### `disable_rescue_from`

- **Type:** Boolean
- **Default:** `false` (the framework does install the rescues)

When `true`, the framework *won't* install its default `rescue_from` handlers for
`ActionController::ParameterMissing`, `ActiveRecord::RecordNotFound`, `ActiveRecord::RecordInvalid`,
etc. The full list of rescued exceptions is in the Controllers section under
[Error Handling](../03_controllers/#error-handling).

Use this if you have a stricter global error-handling scheme and want to install all handlers
yourself. Read at the time each controller's `include RESTFramework::Controller` runs.

### `label_fields`

- **Type:** Array of strings
- **Default:** `%w[ name label login title email username url ]`

The list of "label-like" columns the framework probes when picking default `sub_fields` for
associations. The first column from this list that exists on the associated model is used as
the label alongside the primary key. Add domain-specific label columns here to get nicer
defaults:

```ruby
config.label_fields += %w[ slug handle ]
```

### `search_columns`

- **Type:** Array of strings
- **Default:** `label_fields + %w[ description note ]`

The list of columns that `SearchFilter` searches by default when a controller has no
`search_fields` set. The framework intersects this list with the controller's `fields` to
decide what's searchable. Customize it globally if your domain uses different searchable-text
column names (`summary`, `bio`, etc.).

### `read_only_fields`

- **Type:** Array of strings
- **Default:** `%w[ created_at created_by created_by_id updated_at updated_by updated_by_id _method utf8 authenticity_token ]`

The list of fields treated as read-only by every controller that doesn't override
`read_only_fields`. Read-only fields are included in serialized output but excluded from strong
params, so the API won't accept them in request bodies.

If your app has extra audit columns (`deleted_at`, `version`, etc.), add them here.

### `write_only_fields`

- **Type:** Array of strings
- **Default:** `%w[ password password_confirmation ]`

Counterpart to `read_only_fields` — fields that are accepted in request bodies but never
serialized back out. Useful for secrets like passwords.

### `inflect_acronyms`

- **Type:** Array of strings
- **Default:** `%w[ ID IDs REST API APIs ]`

Acronyms the framework preserves when titleizing field and controller names for display in the
browsable API and OpenAPI labels. Without this, "API" would become "Api" and "ID" would become
"Id" after `titleize`.

Append rather than overwrite so you keep the useful defaults:

```ruby
config.inflect_acronyms += %w[ URL UUID HTTP HTTPS JWT ]
```

### `use_vendored_assets`

- **Type:** Boolean
- **Default:** `false`

By default, the browsable API loads Bootstrap, Bootstrap Icons, highlight.js, NeatJSON, and Trix
from public CDNs with SRI integrity hashes. When this is `true`, the engine adds vendored copies of
each asset to the Rails precompile list, so the browsable API works without outbound network access.

Use this for air-gapped deploys, strict CSPs, or internal networks that don't reach the CDNs.
Requires Propshaft (default on Rails 8+) or Sprockets.

```ruby
# config/initializers/rest_framework.rb
RESTFramework.configure do |config|
  config.use_vendored_assets = true
end
```

### `large_reverse_association_tables`

- **Type:** Array of strings (table names)
- **Default:** `nil`

When the framework is computing default `fields` for a model, it normally includes all reverse
associations. For some tables this is catastrophically expensive — imagine a `User` with a
`has_many :events` relationship to a table with millions of rows; exposing `events` as a default
field would cause any default serialization to be disastrous.

List those table names here and the framework will skip them when computing default fields:

```ruby
config.large_reverse_association_tables = %w[ events audit_logs page_views ]
```

This only affects defaulting — you can still opt a specific field in by listing it in `fields`.

## Typical Production Initializer

```ruby
# config/initializers/rest_framework.rb
RESTFramework.configure do |config|
  # Skip expensive default fields we never want to serialize.
  config.large_reverse_association_tables = %w[ audit_events page_views ]

  # Treat more timestamps/audit columns as read-only.
  config.read_only_fields += %w[ deleted_at ]

  # Extra acronyms for labels.
  config.inflect_acronyms += %w[ URL UUID JWT HTTP HTTPS ]

  # Air-gapped? Serve browsable-API assets ourselves.
  config.use_vendored_assets = ENV["OFFLINE"] == "1"
end
```
