# Routers

You can route RESTful controllers with the normal utilities that Rails provides. However, the REST
framework also provides some helpers to route controllers using attributes of the controllers
themselves.

## Routing the API Root

Your API root should probably have some content describing how one can authenticate with the API,
and what sub-controllers exist in the API. The API root can also be a great place to put singleton
actions on your API, if needed.

There are two common ways for an API root to be implemented.

### Inherited API Root

You likely have an API controller that your other controllers inherit from, like this:

```shell
app/controllers/
├── api
│   ├── groups_controller.rb
│   ├── movies_controller.rb
│   ├── marbles_controller.rb
│   └── users_controller.rb
├── api_controller.rb
└── application_controller.rb
```

If your controllers in the `api` directory inherit from `ApiController` and you want root actions on
`ApiController`, then you would setup your root route in the top-level namespace, like this:

```ruby
Rails.application.routes.draw do
  rest_root :api
  namespace :api do
    ...
  end
end
```

However, note that actions defined on `ApiController` are defined on all sub-controllers, so if
you're using `match` rules to route controllers, then this may lead to undesired behavior.

### Dedicated API Root

A better way might be to dedicate a controller for the API root, which would prevent actions and
properties defined on the root API from propagating to the rest of the namespace through
inheritance. You would add a `RootController` so your directory would look like this:

```shell
app/controllers/
├── api
│   ├── groups_controller.rb
│   ├── movies_controller.rb
│   ├── root_controller.rb
│   ├── marbles_controller.rb
│   └── users_controller.rb
├── api_controller.rb
└── application_controller.rb
```

Now you can route the root in the `:api` namespace, like this:

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_root  # By default this will find and route `Api::RootController`.
    ...
  end
end
```

## Resourceful Routing

The REST Framework provides resourceful routers `rest_resource` and `rest_resources`, analogous to
Rails' `resource` and `resources`. These routers will inspect their corresponding controllers and
route `extra_actions` (aliased with `extra_collection_actions`) and `extra_member_actions`
automatically.

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_root
    rest_resource :user
    rest_resources :movies
  end
end
```

## Non-resourceful Routing

The `rest_route` non-resourceful router does not route the standard resource routes (`index`,
`create`, `show`, `list`, `update`, `delete`). Any actions must be defined as `extra_actions` on the
controller.

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_root
    rest_route :network
  end
end
```
