# Routers

You can route REST Framework controllers with the regular Rails routing helpers, but the framework
provides two dedicated routers (`rest_root` and `rest_route`) that introspect the controller and
wire up extra actions, built-in actions, and bulk routes automatically.

- `rest_root` — route a controller's `root` action to the current scope root.
- `rest_route` — route a controller; if the controller has a `model`, CRUD actions are routed
  automatically, otherwise only the `root` action and `extra_actions` are routed.

## Routing the API Root

Your API root typically explains how to authenticate and provides a description of the API.

The recommended pattern is a dedicated `RootController` inside the `api` namespace, so root-specific
actions stay isolated from your resource controllers:

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
    rest_route :movies
    rest_route :users
  end
end
```

`rest_root` accepts a controller name override (`rest_root :home` would route
`Api::HomeController#root` to `/api/`).

## Resourceful Routing

When a controller has a `model` set, `rest_route` automatically routes the standard CRUD actions:

1. For plural controllers: `index`, `create`, `show`, `update`, `destroy`.
2. For singular controllers (`self.singular = true`): `create`, `show`, `update`, `destroy` (no
   `index`, no `:id` in URLs).
3. Actions are only routed if the controller defines the method and it is not listed in
   `excluded_actions`.
4. If `bulk = true`, `update_all` (`PATCH`/`PUT /resource`) and `destroy_all`
   (`DELETE /resource`) are also routed. Bulk `create` (array POSTs) uses the regular `create`
   route. Individual bulk actions can be opted out through `excluded_actions`.

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_root
    rest_route :user       # Singular: no :id in URLs, no #index route.
    rest_route :movies     # Plural: includes the full CRUD set.
  end
end
```

### Overriding Plurality with `singular`

A controller can force singular or plural routing regardless of which helper routes it:

```ruby
class Api::UserController < ApiController
  self.model = User
  self.singular = true   # Always render singular routes.
end
```

### Passing Options

`rest_route` accepts options like `path:`, `as:`, and `controller:`, which are forwarded to the
underlying Rails resource helper.

```ruby
rest_route :movies, path: "films", as: "films"
```

## Non-resourceful Routing

When a controller has no `model` set, `rest_route` routes the `root` action and any `extra_actions`
defined on the controller. Use it for singleton API endpoints like a network status or health check:

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
  - The controller has no `model` set.
  - The action method is not defined on the controller.
  - The action is listed in `excluded_actions`.
- Bulk routes (`update_all`, `destroy_all`) are only added when both `model` and `bulk = true` are
  set on the controller. Individual bulk actions can be removed via `excluded_actions`.
