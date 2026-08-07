# Routers

You can route REST Framework controllers with the regular Rails routing helpers, but the framework
provides dedicated `rest_resource` / `rest_resources` helpers that introspect the controller and
wire up its built-in actions, extra actions, and bulk routes automatically.

- **`rest_resource`** routes a **single** controller.
- **`rest_resources`** routes **several** controllers that share the same options, in one call.

The `s` is about how many **controllers** you route, not plural vs. singular routes. Whether a
controller routes via the underlying Rails `resource` or `resources` (member `:id` in the URL, an
`index` action, and so on) is decided by the controller's own config (`singular`, and whether it has
a `model`), so a single plural resource is still `rest_resource :movies`.

They route a controller by name, matched **exactly** to the controller class (the camelized name
plus `Controller`, in the current scope — e.g. `rest_resource :movies` needs `MoviesController`).
If the controller has a `model`, the CRUD actions are routed automatically; otherwise only the
controller's `index` (which serves as the root) and the actions from its `actions` store are routed.

Use `rest_resources` to route several simple controllers at once, to condense a namespace:

```ruby
namespace :api do
  rest_resources :movies, :users, :genres
end
```

Per-name options (`path:`, `as:`, `controller:`) and a block for nesting only make sense for a
single controller, so they're rejected when several names are given — reach for `rest_resource`
there.

## Routing the API Root

Your API root typically explains how to authenticate and provides a description of the API. There is
no special "root" action or router — a controller without a `model` renders its `index_content` at
its index path (`/`), and that serves as the root. Override `index_content` to customize the payload
(it defaults to the controller's `description`):

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  def index_content
    {
      message: "Welcome to the API.",
      how_to_authenticate: "Use a Bearer token or the `api_key` query parameter.",
    }
  end
end
```

Because a controller's declared actions are local by default (they don't propagate to subclasses),
root-specific extra actions stay isolated from your resource controllers without a dedicated
controller. Route your API's base controller to serve the root:

```ruby
Rails.application.routes.draw do
  rest_resource :api  # `ApiController` serves the `/api` root.

  namespace :api do
    rest_resources :movies, :users
  end
end
```

Nested namespaces follow the same pattern — route each namespace's base controller to serve its
root (`rest_resource :demo` finds `Api::DemoController` and serves `/api/demo`).

## Resourceful Routing with Models

When a controller has a `model` set, `rest_resource` automatically routes the standard CRUD actions:

1. For plural controllers: `index`, `create`, `show`, `update`, `destroy`.
2. For singular controllers (`self.singular = true`): `create`, `show`, `update`, `destroy` (no
   `index`, no `:id` in URLs).
3. Built-in actions are only routed when applicable and unless removed via `remove_actions`.
4. If `bulk = true`, `update_all` (`PATCH`/`PUT /resource`) and `destroy_all`
   (`DELETE /resource`) are also routed. Bulk `create` (array POSTs) uses the regular `create`
   route. Individual bulk actions can be opted out through `remove_actions`.

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_resource :user    # Routes singular: no :id in URLs, no #index route.
    rest_resource :movies  # Routes plural: the full CRUD set, with :id.
  end
end
```

### Overriding Plurality with `singular`

A controller can force singular or plural routing regardless of which helper routes it:

```ruby
class Api::UserController < ApiController
  self.model = User
  self.singular = true  # Always render singular routes.
end
```

### Passing Options

`rest_resource` accepts options like `path:`, `as:`, and `controller:`, which are forwarded to the
underlying Rails resource helper. (These are per-controller, so they're only valid on the
single-controller `rest_resource`, not the multi-controller `rest_resources`.)

```ruby
rest_resource :movies, path: "films", as: "films"
```

Pass `helpers: false` to route a resource without any URL/path helpers. This is useful when a
singular and a plural resource of the same model live in the same scope — like a `resource :user`
("the current user") next to `resources :users` — where both would otherwise claim the `user`
helper (a name collision Rails raises on, since `as: false`/`nil` doesn't suppress helpers there):

```ruby
rest_resources :users        # api_users, api_user, ...
rest_resource :user, helpers: false   # routed, but contributes no helpers
```

### Nested Resources

Give `rest_resource` a block to nest resources like Rails' `resources`, so a child routes under the
parent's member (`/movies/:movie_id/genres`):

```ruby
namespace :api do
  rest_resource :movies do
    rest_resource :genres   # /api/movies/:movie_id/genres
  end
end
```

The nested controller is resolved in the **current** module scope (here `Api::GenresController`),
like Rails — a nested resource is not auto-namespaced into `Api::Movies::GenresController`.
Reuse the same top-level controller; use an explicit `scope`/`namespace` only if you genuinely want
a separate namespaced controller.

By default the nested recordset is **auto-scoped to the parent**: a request to
`/api/movies/:movie_id/genres` serves `Movie.find(params[:movie_id]).genres` (the association is
resolved from the parent, so `belongs_to`, `has_many`, and `has_and_belongs_to_many` children all
work). This follows the **whole chain** when nested more than one level deep —
`/api/movies/:movie_id/genres/:genre_id/tracks` scopes to
`Movie.find(movie_id).genres.find(genre_id).tracks`, enforcing every link (a broken one `404`s).
Only path parameters drive this, so a client can't forge scoping via the query string.

Each parent is looked up through **its own controller's `get_recordset`** (the sibling controller
found by model, the same discovery used for association fields), so a parent the current user can't
reach simply isn't found — access scoping is enforced at every level, existence-hiding style. This
requires the parent controller's `get_recordset` to be derivable from the request (the usual
`current_user`); set `scope_nested_through_controllers = false` to look parents up directly on the
model instead.

Override `get_recordset` to take full control, or set `scope_nested_by_parent = false` to disable
the auto-scoping entirely.

## Non-model Routing

When a controller has no `model` set, `rest_resource` routes its `index` (the root, which renders
`index_content`) and any actions from the controller's `actions` store. Use it for singleton API
endpoints like a network status or health check:

```ruby
class Api::NetworkController < ApiController
  add_action(:ping, :get)
  add_action(:stats, :get)

  def ping
    render(api: { status: "ok" })
  end

  def stats
    render(api: { ... })
  end
end
```

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_resource :network
  end
end
```

## Routing Behavior Details

- The actions from the controller's `actions` / `member_actions` store are routed automatically.
- If an action specifies `path:`, the framework uses that as the URL segment; otherwise the action
  name is used. Useful when you need a path that would collide with an existing controller method.
- When declaring an action, `methods` may be a single method symbol or an array of methods, with
  optional `path:` and `metadata:` (used for OpenAPI documentation).
- The `options` action is always routed, so clients can fetch OpenAPI metadata for an endpoint with
  a regular `OPTIONS` request.
- Built-in actions are routed only when applicable: `create`/`show`/`update`/`destroy` require a
  `model`; `index`/`create`/`destroy` are skipped for singular controllers; bulk routes require
  `bulk = true`.
- Any built-in action can be removed via `remove_actions`.
