# OpenAPI

REST Framework auto-generates an OpenAPI document for every controller, reflecting the
real configuration that drives the API: `fields` (membership and per-field `config`), validators, field options,
association metadata, rich-text and attachment fields, bulk support, and more. The document is
served from the controller's `OPTIONS` endpoint — no extra setup, no drift between spec and
behavior.

## Fetching the Document

Every REST Framework controller responds to `OPTIONS` with its OpenAPI document:

```bash
curl -X OPTIONS https://example.com/api/movies
```

From a browser, the `OPTIONS` action also has an HTML rendering accessible from the route list
in the browsable API, so you can explore the document interactively.

## Customizing the Document

The fields of the `info` block and the tag description come from standard controller
attributes:

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.title = "Movies API"
  self.description = "Read and manage movie records. Supports bulk operations."
  self.version = "2026.04"
end
```

- `title` → `info.title` and the tag name.
- `description` → `info.description` and the tag description.
- `version` → `info.version` (defaults to empty).

If `title` is unset, it falls back to the controller's titleized class name, with
`RESTFramework.config.inflect_acronyms` applied so things like `"ID"`, `"API"`, and `"REST"`
stay capitalized.

## Schema Generation

When the controller has a `model`, the OpenAPI document includes a full schema for that model
under `components.schemas.<SchemaName>`. The schema name defaults to the controller class name
with `"Controller"` stripped and `"::"` replaced with `"."` — so `Api::MoviesController` becomes
`Api.Movies`. Every `field` becomes a property:

- `title` — set from the label (either the field's `config` `label:` or the auto-generated titleized
  name).
- `type` — derived from the column or attribute (`string`, `integer`, `boolean`, etc.), or set
  to `array` / `object` for associations.
- `readOnly` — `true` when the field is marked read-only (primary keys, fields in
  `read_only_fields`, method fields, or fields with `read_only: true` in their `config`).
- `default` — default from the schema or the field's `config`.
- `enum` — the allowed values, only when the column is a true ActiveRecord enum.
- `required` — fields inferred from `null: false` or presence validators land in the schema's
  top-level `required` array.

On top of the standard OpenAPI vocabulary, the framework adds several `x-rrf-*` extensions for
browsable-API clients and tools that want to consume the full field metadata.

## `x-rrf-*` Extensions

### Schema-level (per field)

| Extension                            | Description                                                                                 |
| ------------------------------------ | ------------------------------------------------------------------------------------------- |
| `x-rrf-kind`                         | `"column"`, `"association"`, `"method"`, `"attribute"`, `"rich_text"`, or `"attachment"`.   |
| `x-rrf-rich_text`                    | `true` when the field is an Action Text rich text attribute.                                |
| `x-rrf-attachment`                   | `:has_one_attached` or `:has_many_attached` for Active Storage attachments.                 |
| `x-rrf-options`                      | Full `{ value => label }` choice map for the field (enums, or any field with configured `options`); standard `enum` only lists the values, and only for true enums. |
| `x-rrf-validators`                   | Hash of validator kind → array of option hashes, for every model-level validator.           |
| `x-rrf-reflection`                   | Association metadata: `class_name`, `foreign_key`, `association_foreign_key`, `association_primary_key`, `inverse_of`, `join_table`. |
| `x-rrf-association_pk`               | The primary key of the associated class.                                                    |
| `x-rrf-association_fields`           | Fields used for serializing/filtering/ordering the association.                             |
| `x-rrf-association_fields_metadata`  | Kind (`column` vs `method`) for each association field.                                     |
| `x-rrf-id_field`                     | The scalar id field (e.g., `user_id`, `tag_ids`).                                           |
| `x-rrf-nested_attributes_options`    | `accepts_nested_attributes_for` options for the association.                                |

### Document-level (for model controllers)

| Extension             | Description                                                                           |
| --------------------- | ------------------------------------------------------------------------------------- |
| `x-rrf-primary_key`   | The model's primary key name.                                                         |
| `x-rrf-callbacks`     | The controller's `_process_action_callbacks` (for tools that want to show filters).   |
| `x-rrf-bulk-create`   | `true` when the controller has `bulk = true` — bulk create overloads the collection POST, so this is the only way to indicate it in OpenAPI. |

### Route-level (on each operation)

Any extra metadata you provide via `add_action` flows through
to the operation spec:

```ruby
add_action(:disable, :patch, type: :member, metadata: {
  label: "Disable Movie",
  description: "Marks the movie as disabled without deleting it.",
})
```

- `metadata[:label]` → the operation `summary` (default: the action name).
- `metadata[:description]` → the operation `description`.
- Anything else under `metadata` → attached as `x-rrf-metadata` on the operation.

## Responses and Request Bodies

The framework populates standard OpenAPI responses automatically:

- Built-in `create` → `201`.
- Built-in `destroy` → `204`.
- Anything else → `200`.
- Non-GET builtin actions also get `400` (`$ref: BadRequest`) and `404` (`$ref: NotFound`)
  response schemas, plus a shared `Error` schema for both.
- `POST` / `PUT` / `PATCH` operations get a `requestBody` referencing the model's schema.

## Including Child Controllers

By default, each controller's document covers only its own routes. To aggregate child
controllers into a single parent document (useful for generating a one-big-document view of a
sub-API), set:

```ruby
class Api::DemoController < ApiController
  include RESTFramework::Controller
  self.openapi_include_children = true
end
```

With this, `OPTIONS /api/demo` returns a merged document containing paths, tags, and schemas
from every child controller reachable from the root.

## Consuming the Document

Because the framework emits a spec-compliant OpenAPI 3.1.1 document, any standard tool works:

- **Swagger UI / Redoc** — point them at your `OPTIONS` URL.
- **openapi-generator-cli** — generate client libraries in any language.
- **Stainless / Fern / orval** — generate typed SDKs.
- **Postman / Insomnia / Bruno** — import the document as a collection.
