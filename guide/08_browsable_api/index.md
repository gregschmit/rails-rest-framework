# The Browsable API

Every REST Framework controller serves a fully-featured HTML browsable UI alongside its JSON and
XML responses. This isn't a stripped-down admin console — it's the same endpoints, with the same
filters, pagination, and metadata, rendered in a way that's pleasant for humans. It makes API
development dramatically faster because you can explore, test, and demo your API from any
browser.

## How It Works

When a request's `Accept` header matches `text/html`, the framework renders its Rails layout
(`app/views/layouts/rest_framework.html.erb`) populated from the same data that would have been
returned as JSON. The layout gives you:

- Breadcrumbs back up the URL hierarchy.
- The controller's title and description.
- Request metadata (the current path, method, status).
- The serialized JSON and XML payloads, pretty-printed and syntax-highlighted.
- A route listing showing every action on this controller (and nested controllers).
- Generated HTML forms for `POST` / `PUT` / `PATCH`, respecting `fields`, `field_config`, and
  validators.
- A raw-body form for arbitrary JSON/XML payloads (useful for bulk actions).
- Dark/light/system theme toggle.

If an endpoint responds to `OPTIONS` (every controller does by default), the page also provides
a button to fetch and display the OpenAPI document for that endpoint.

## Setting the Title and Description

`title` and `description` are class attributes on every controller. They drive the browsable
API heading and are also picked up by the OpenAPI document.

```ruby
class Api::MoviesController < ApiController
  self.model = Movie
  self.title = "Movies API"
  self.description = "Read and manage movie records. Supports bulk operations."
end
```

If `title` is not set, the framework falls back to the controller name (titleized, with acronyms
from `RESTFramework.config.inflect_acronyms` preserved). `description` is blank by default.

For request-time customization (e.g., showing a per-user message), set the instance variables
from a `before_action`:

```ruby
before_action do
  @title = "#{current_user.name}'s Movies"
  @description = "All movies visible to you."
end
```

## Instance-Variable Hooks

The layout reads several `@` variables at render time. You can set them from a `before_action`,
an override, or in any action that renders. The following are recognized:

| Variable                 | Effect                                                                             |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `@title`                 | `<title>` tag and heading text. Defaults to the controller's inferred title.       |
| `@description`           | Shown under the heading. Defaults to the controller's `description` attribute.     |
| `@heading_title`         | Override just the heading (`<h1>`) without changing `<title>`.                     |
| `@header_title`          | Text shown in the dark navbar at the top. Defaults to "Rails REST Framework".      |
| `@template_logo_text`    | Full override for the navbar brand (takes precedence over `@header_title`).        |
| `@hide_breadcrumbs`      | When truthy, suppress the breadcrumb row.                                          |
| `@hide_heading`          | When truthy, suppress the heading/description row entirely.                        |
| `@hide_request_metadata` | When truthy, suppress the request-metadata row.                                    |

### Example: Branding an API Family

Use a `before_action` in your shared parent controller to brand every descendant page:

```ruby
class Api::DemoController < ApiController
  include RESTFramework::Controller

  before_action do
    @header_title = "Rails REST Framework Demo API"
  end
end
```

Now every controller under `Api::Demo` inherits the branded header without touching individual
controllers.

### Example: Hiding Chrome on the Root

```ruby
class Api::RootController < ApiController
  before_action(only: :root) do
    @hide_breadcrumbs = true
    @hide_request_metadata = true
  end
end
```

## Adding to the Layout with `content_for`

Two Rails `content_for` regions are available:

### `:head`

Inject anything into the `<head>` — meta tags, custom stylesheets, scripts:

```erb
<!-- app/views/api/movies/_head.html.erb -->
<% content_for :head do %>
  <meta name="robots" content="noindex">
  <link rel="stylesheet" href="<%= asset_path('api_overrides.css') %>">
<% end %>
```

### `:header_menu`

Replaces the default dark/light mode toggle in the navbar — useful for adding a "sign out" link,
a link to API docs, or environment indicators:

```erb
<!-- app/views/api/_header_menu.html.erb -->
<% content_for :header_menu do %>
  <div class="navbar-text text-light">
    <%= current_user.email %>
    <%= link_to "Sign out", destroy_user_session_path, method: :delete, class: "text-light ms-3" %>
  </div>
<% end %>
```

Rendering these in a `before_action` applies them globally:

```ruby
before_action { render("api/_header_menu", layout: false) && nil }
```

## "Extra" Extension Partials

Empty "extra" partials ship with the gem specifically so you can override them without having to
override the whole layout:

| Partial                                           | Renders in                                   |
| ------------------------------------------------- | -------------------------------------------- |
| `rest_framework/head/_extra.html.erb`             | End of `<head>`, after styles and scripts.   |
| `rest_framework/heading/_extra.html.erb`          | Inside the heading row, after the title.     |
| `rest_framework/heading/actions/_extra.html.erb`  | Inside the action button cluster.            |

To override, create a file at the same path in your app (e.g.,
`app/views/rest_framework/heading/actions/_extra.html.erb`). Rails' view lookup will find your
version first. This is the cleanest way to add persistent UI elements.

## Replacing the Whole Layout

If you need more control, set `self.layout("my_layout")` on a controller and provide your own
layout. The framework exposes the data your layout needs through the same instance variables,
plus:

- `@payload` — the raw object that was serialized (hash, relation, record, or `""`).
- `@json_payload` / `@xml_payload` — the pre-serialized string forms, when those formats are
  enabled. Set to `""` for no-content (`DELETE`) responses.
- `@route_groups` — a hash of `{ controller_name => [ route_info, ... ] }` for every route
  reachable from the current path.

The `@route_groups` data is the same structure that powers the default routes/forms panel. You
can reuse it to build your own nav.

## Rendering Your Own Template

If Rails finds a template matching the action (`app/views/api/movies/index.html.erb`, etc.),
it's rendered inside the layout with `@payload`, `@json_payload`, `@xml_payload`, `@title`,
`@description`, and `@route_groups` available. Otherwise, the layout renders the built-in
routes/forms/payload blocks with no additional body content.

## Disabling the Browsable API

For services where you'd rather not expose an HTML UI:

```ruby
class Api::InternalController < ApiController
  self.rescue_unknown_format_with = nil   # Don't fall back for HTML requests.

  before_action do
    if request.format.html?
      head(:not_acceptable) and return
    end
  end
end
```

You can also set the layout to `false` (`self.layout(false)`) to skip the RRF layout while
still rendering raw responses.

## Forms

For `POST` / `PUT` / `PATCH` routes, the browsable API renders two form types:

- **HTML Form** — a traditional Rails form, driven by `fields` and `field_config`. It respects
  required fields, default values, enum dropdowns, association pickers, and nested attributes.
  Only shown when the controller has a `model`.
- **Raw Form** — a textarea for pasting a JSON, XML, or form-encoded body, with a content-type
  selector. Used for bulk actions, complex payloads, or when you need to test malformed input.

If the controller has `enable_active_storage = true` and an attachment field, a files sub-form
appears when the raw form is switched to `multipart/form-data`.
