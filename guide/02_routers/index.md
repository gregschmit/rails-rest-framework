# Routers

You can route REST Framework controllers with the regular Rails routing helpers, but the
framework provides three dedicated routers (`rest_root`, `rest_route`, `rest_resource`, and
`rest_resources`) that introspect the controller and wire up extra actions, built-in actions, and
bulk routes automatically.

- `rest_root` — route a controller's `root` action to the current scope root.
- `rest_route` — route a non-resourceful controller (only `extra_actions`, no CRUD).
- `rest_resource` / `rest_resources` — route a resourceful controller (singular/plural), analogous
  to Rails' `resource`/`resources`, plus `extra_actions`, `extra_member_actions`, and bulk actions
  from the controller's configuration.

## Routing the API Root

Your API root typically explains how to authenticate and provides a description of the API.

The recommended pattern is a dedicated `RootController` inside the `api` namespace, so
root-specific actions and configuration don't propagate through inheritance to every descendant
resource controller:

```text
app/controllers/
├── api/
│   ├── groups_controller.rb
│   ├── movies_controller.rb
│   ├── root_controller.rb
│   └── users_controller.rb
├── api_controller.rb
└── application_controller.rb
```

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_root  # Finds Api::RootController and routes `#root` to '/'.
    rest_resources :movies
    rest_resources :users
  end
end
```

`rest_root` accepts a controller name override (`rest_root :home` would route
`Api::HomeController#root` to `/api/`) and an `action:` kwarg (`rest_root action: :welcome` would
route `Api::RootController#welcome`).

## Resourceful Routing

`rest_resource` (singular) and `rest_resources` (plural) are analogous to Rails' `resource` and
`resources`, but they add three things:

1. They skip built-in CRUD actions that are excluded via `excluded_actions` or for which the
   controller isn't configured (e.g., a controller without `model` skips all CRUD actions).
2. They route every `extra_actions` entry on the collection and every `extra_member_actions`
   entry on the member.
3. If the controller has `bulk = true`, they route `update_all` (`PATCH`/`PUT /resource`) and
   `destroy_all` (`DELETE /resource`). Bulk `create` (array POSTs) uses the regular `create`
   route. Bulk actions can be individually opted out through `excluded_actions`.

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_root
    rest_resource :user       # Singular: no :id in URLs, no #index route.
    rest_resources :movies    # Plural: includes the full CRUD set.
  end
end
```

### Overriding Plurality with `singleton_controller`

A controller can force singular or plural routing regardless of which helper routes it:

```ruby
class Api::UserController < ApiController
  self.model = User
  self.singleton_controller = true   # Always render singular routes.
end
```

### Passing Options

`rest_resource` / `rest_resources` accept the same options as Rails' `resource(s)`, including
`only:`, `except:`, `path:`, `as:`, and `controller:`. Options are forwarded through.

```ruby
rest_resources :movies, path: "films", as: "films"
```

### Unscoped Nested Blocks

Normally, a block passed to `rest_resources` is auto-scoped to the resource's module/path. Pass
`unscoped: true` to disable the scope:

```ruby
rest_resources :movies, unscoped: true do
  # Routes here won't be nested under /movies/:movie_id.
end
```

## Non-resourceful Routing

`rest_route` does **not** route the standard REST actions (`index`, `show`, `create`, `update`,
`destroy`). Only `extra_actions` defined on the controller get routed (plus `options`, since the
framework supports `OPTIONS`-based metadata). Use it for singleton API endpoints like a network
status or health check:

```ruby
class Api::NetworkController < ApiController
  self.extra_actions = { ping: :get, stats: :get }

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
    rest_root
    rest_route :network
  end
end
```

## Routing Behavior Details

- `extra_actions` is aliased to `extra_collection_actions`; you can use either.
- If an extra action specifies `path:`, the framework uses that as the URL segment; otherwise the
  action name is used. Useful when you need a path that would collide with a method name.
- `extra_actions` hash values may be a single method symbol, an array of methods, or a hash with
  `methods:`, `path:`, and `metadata:` (used for OpenAPI documentation).
- The `options` action is always routed when the controller responds to it, so clients can fetch
  OpenAPI metadata for an endpoint with a regular `OPTIONS` request.
- Built-in CRUD routes are skipped when:
  - The controller has no `model` set (no default CRUD action methods exist on the controller).
  - The action is listed in `excluded_actions`.
- Bulk routes (`update_all`, `destroy_all`) are only added when both `model` and `bulk = true` are
  set on the controller. Individual bulk actions can be removed via `excluded_actions`.
