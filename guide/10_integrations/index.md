# Integrations

REST Framework integrates with several popular Rails libraries out of the box. This section
pulls together the integration points that are otherwise scattered across the other sections.

## Action Text

Opt in at the controller level by setting `enable_action_text = true`:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  propagate do
    self.enable_action_text = true
  end
end
```

With this flag on, for a model like:

```ruby
class Article < ApplicationRecord
  has_rich_text :body
end
```

the framework will:

- Include `body` in the default `fields` list.
- Mark the field as `kind: "rich_text"` in `field_configuration` and the OpenAPI schema
  (`x-rrf-rich_text: true`).
- Serialize the field as the plain-text `to_s` representation (the prosemirror/HTML payload is
  stripped).
- Accept a plain string in the request body for create/update.
- Render a [Trix](https://trix-editor.org) editor in the browsable API's HTML form.

If you need the raw HTML or formatted output rather than plain text, define your own method on
the model and include it in `fields` instead:

```ruby
class Article < ApplicationRecord
  has_rich_text :body

  def body_html
    body.to_s   # Or `body.body.to_html` for Trix-formatted HTML.
  end
end

class Api::ArticlesController < ApiController
  self.model = Article
  self.fields = [ :id, :title, :body_html ]
  # No `enable_action_text` — we're handling serialization manually.
end
```

## Active Storage

Opt in at the controller level with `enable_active_storage = true`:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  propagate do
    self.enable_active_storage = true
  end
end
```

For a model like:

```ruby
class Movie < ApplicationRecord
  has_one_attached :poster
  has_many_attached :trailers
end
```

### Serialization

Attached files serialize as:

```json
{ "filename": "poster.png", "signed_id": "...", "url": "..." }
```

For `has_many_attached`, an array of those hashes.

### Accepting Uploads

The controller accepts four payload shapes for attachment fields:

1. **Multipart upload** — a standard `<input type="file">` form submission.
2. **ActiveStorage hash**:
   ```json
   { "io": "...", "content_type": "image/png", "filename": "poster.png" }
   ```
3. **Base64 data URL** — useful for clients that can only send JSON:
   ```json
   "data:image/png;base64,iVBORw0KGgo..."
   ```
   The framework decodes the base64 payload, builds the ActiveStorage hash automatically, and
   infers the filename extension from the content type.
4. **`signed_id` string** — for keeping an existing attachment.

### Mixed Payloads for `has_many_attached`

A single `has_many_attached` field can accept an array that mixes all four forms:

```json
"trailers": [
  "signed_id_for_existing_attachment",
  "data:video/mp4;base64,AAAA...",
  { "io": "...", "content_type": "video/mp4", "filename": "trailer.mp4" }
]
```

## TranslateEnum

If you use the [`translate_enum`](https://github.com/shlima/translate_enum) gem, REST Framework
automatically includes translated values in field metadata. For a model like:

```ruby
class User < ApplicationRecord
  enum :state, { default: 0, pending: 1, banned: 2, archived: 3 }
  translate_enum :state
end
```

the field config for `state` will contain `enum_translations`, and the OpenAPI schema will
expose both the raw values and the translated labels:

## Ransack

For more advanced filtering than what `QueryFilter` / `SearchFilter` can express (joins,
aggregations, custom predicates), add the
[`ransack`](https://github.com/activerecord-hackery/ransack) gem to your Gemfile and include its
filter backend:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  propagate do
    self.filter_backends += [ RESTFramework::RansackFilter ]
  end
end
```

Clients can now pass Ransack search hashes via a `q` query parameter.

You still need to configure `ransackable_attributes` / `ransackable_associations` on your models —
Ransack's own safety controls apply, and the framework doesn't bypass them.

## ActiveModel::Serializers

If your project already uses `active_model_serializers`, you can point `serializer_class` at an AMS
serializer and the framework will wrap it in an adapter compatible with the rest of the pipeline:

```ruby
class UserSerializer < ActiveModel::Serializer
  attributes :id, :login, :email
  has_many :movies
end

class Api::UsersController < ApiController
  self.model = User
  self.serializer_class = UserSerializer
end
```

Notes:

- `disable_adapters_by_default` is `true` by default, so the framework passes `adapter: nil` to AMS.
  This avoids AMS's default adapter quirks (like serializing `[]` as `{"":[]}`). Pass `adapter:`
  explicitly if you want the AMS default.
- The AMS adapter wrapper is added automatically via
  `RESTFramework::ActiveModelSerializerAdapterFactory` — no manual bridging is needed.
- For controllers that don't set `serializer_class`, the framework continues to use
  `NativeSerializer`, so you can mix AMS and native serializers in the same app.
