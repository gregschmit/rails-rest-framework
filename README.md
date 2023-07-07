# Rails REST Framework

[![Gem Version](https://badge.fury.io/rb/rest_framework.svg)](https://badge.fury.io/rb/rest_framework)
[![Pipeline](https://github.com/gregschmit/rails-rest-framework/actions/workflows/pipeline.yml/badge.svg)](https://github.com/gregschmit/rails-rest-framework/actions/workflows/pipeline.yml)
[![Coverage](https://coveralls.io/repos/github/gregschmit/rails-rest-framework/badge.svg?branch=master)](https://coveralls.io/github/gregschmit/rails-rest-framework?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/ba5df7706cb544d78555/maintainability)](https://codeclimate.com/github/gregschmit/rails-rest-framework/maintainability)

A framework for DRY RESTful APIs in Ruby on Rails.

**The Problem**: Building controllers for APIs usually involves writing a lot of redundant CRUD
logic, and routing them can be obnoxious. Building and maintaining features like ordering,
filtering, and pagination can be tedious.

**The Solution**: This framework implements browsable API responses, CRUD actions for your models,
and features like ordering/filtering/pagination, so you can focus on building awesome APIs.

Website/Guide: [rails-rest-framework.com](https://rails-rest-framework.com)

Demo API: [rails-rest-framework.com/api/demo](https://rails-rest-framework.com/api/demo)

Source: [github.com/gregschmit/rails-rest-framework](https://github.com/gregschmit/rails-rest-framework)

YARD Docs: [rubydoc.info/gems/rest_framework](https://rubydoc.info/gems/rest_framework)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rest_framework"
```

And then run:

```shell
bundle install
```

## Quick Usage Tutorial

This section provides some simple examples to quickly get you started using the framework.

For the purpose of this example, you'll want to add an `api_controller.rb` to your controllers, as
well as a directory for the resources:

```text
controllers/
├─ api_controller.rb
└─ api/
   ├─ root_controller.rb
   ├─ movies_controller.rb
   └─ users_controller.rb
```

### Controller Mixins

The root `ApiController` can include any common behavior you want to share across all your API
controllers:

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  # Setting up a paginator class here makes more sense than defining it on every child controller.
  self.paginator_class = RESTFramework::PageNumberPaginator

  # The page_size attribute doesn't exist on the `BaseControllerMixin`, but for child controllers
  # that include the `ModelControllerMixin`, they will inherit this attribute and will not overwrite
  # it.
  class_attribute(:page_size, default: 30)
end
```

A root controller can provide actions that exist on the root of your API. It's best to define a
dedicated root controller, rather than using the `ApiController` for this purpose, so that actions
don't propagate to child controllers:

```ruby
class Api::RootController < ApiController
  self.extra_actions = {test: :get}

  def root
    return api_response(
      {
        message: "Welcome to the API.",
        how_to_authenticate: <<~END.lines.map(&:strip).join(" "),
          You can use this API with your normal login session. Otherwise, you can insert your API
          key into a Bearer Authorization header, or into the URL parameters with the name
          `api_key`.
        END
      },
    )
  end

  def test
    return api_response({message: "Hello, world!"})
  end
end
```

And here is an example of a resource controller:

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.fields = [:id, :name, :release_date, :enabled]
  self.extra_member_actions = {first: :get}

  def first
    # Always use the bang method, since the framework will rescue `RecordNotFound` and return a
    # sensible error response.
    return api_response(self.get_records.first!)
  end

  def get_recordset
    return Movie.where(enabled: true)
  end
end
```

You can also configure a resource's fields dynamically using `include` and `exclude` keys:

```ruby
class Api::UsersController < ApiController
  include RESTFramework::ModelControllerMixin

  self.fields = {include: [:calculated_popularity], exclude: [:impersonation_token]}
end
```

### Routing

You can use Rails' `resource`/`resources` routers to route your API, however if you want
`extra_actions` / `extra_member_actions` to be routed automatically, then you can use `rest_route`
for non-resourceful controllers, or `rest_resource` / `rest_resources` resourceful routers. To route
the root, use `rest_root`.

```ruby
Rails.application.routes.draw do
  # If you wanted to route actions from the `ApiController`, then you would use this:
  # rest_root :api  # Will find `api_controller` and route the `root` action to '/api'.

  namespace :api do
    rest_root  # Will route `Api::RootController#root` to '/' in this namespace ('/api').
    rest_resources :movies
    rest_resources :users
  end
end
```

## Development/Testing

After you clone the repository, cd'ing into the directory should create a new gemset if you are
using RVM. Then run `bin/setup` to install the appropriate gems and set things up.

The top-level `bin/rails` proxies all Rails commands to the test project, so you can operate it via
the usual commands (e.g., `rails test`, `rails server` and `rails console`).
