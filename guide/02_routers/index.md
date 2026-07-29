# Routers

You can route REST Framework controllers with the regular Rails routing helpers, but the framework
provides a dedicated `rest_route` helper that introspects the controller and wires up its built-in
actions, extra actions, and bulk routes automatically.

`rest_route` routes a controller by name, matched **exactly** to the controller class (the
camelized name plus `Controller`, in the current scope — e.g. `rest_route :movies` requires
`MoviesController`). If the controller has a `model`, the CRUD actions are routed automatically;
otherwise only the controller's `index` (which serves as the root) and the actions from its
`actions` store are routed.

Pass several names to route them all in one call — handy for condensing a namespace:

```ruby
namespace :api do
  rest_route :movies, :users, :genres
end
```

Per-name options (`path:`, `as:`, `controller:`, and a block for nested resources) only apply when a
single name is given.

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
  rest_route :api        # `ApiController` serves the `/api` root.

  namespace :api do
    rest_route :movies
    rest_route :users
  end
end
```

Nested namespaces follow the same pattern — route each namespace's base controller to serve its
root (`rest_route :demo` finds `Api::DemoController` and serves `/api/demo`).

## Resourceful Routing

When a controller has a `model` set, `rest_route` automatically routes the standard CRUD actions:

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

When a controller has no `model` set, `rest_route` routes its `index` (the root, which renders
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
    rest_route :network
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
  `model`; `index` is skipped for singular controllers; bulk routes require `bulk = true`.
- Any built-in action can be removed via `remove_actions`.
