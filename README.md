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
and features like ordering/filtering/pagination, so you can focus on your application logic.

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

To add REST framework features to a controller, include the `Controller` module:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  # Here is where you can set configuration class attributes that will propagate to child
  # controllers.

  # Setting up a paginator class here makes more sense than defining it on every child controller.
  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 30
end
```

Here is what the directory structure might look like for resource controllers:

```text
controllers/
├─ api_controller.rb
└─ api/
   ├─ root_controller.rb
   ├─ movies_controller.rb
   └─ users_controller.rb
```

### Root Controller

It is typically a good pattern for the root of your API to have a dedicated `Api::RootController`
outside the inheritance chain of your other API controllers, so that you can define actions on the
root without them propagating to child controllers, and so you can set global configuration on the
`ApiController`.

```ruby
class Api::RootController < ApiController
  self.extra_actions = {test: :get}

  # The root action is routed by `rest_root`.
  def root
    render(
      api: {
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
    render(api: {message: "Hello, world!"})
  end
end
```

### Resource Controllers

Other API controllers can be associated to a resource/model by setting the `model` class attribute.

```ruby
class Api::MoviesController < ApiController
  self.model = Movie  # Automatically routes the standard CRUD actions for this controller.
  self.bulk = true  # Enables bulk create/update/destroy actions for this controller.
  self.fields = [:id, :name, :release_date, :enabled]
  self.extra_member_actions = {first: :get}

  def first
    # Always use bang methods, since the framework will rescue `RecordNotFound` and return a
    # sensible error response.
    render(api: self.get_records.first!)
  end

  def get_recordset
    return Movie.where(enabled: true)
  end
end
```

When `fields` is nil, then it will default to all columns. The `fields` attribute can also be a hash
to include or exclude fields rather than defining them manually:

```ruby
class Api::UsersController < ApiController
  self.fields = {include: [:calculated_popularity], exclude: [:impersonation_token]}

  # You can even disable some of the builtin actions. For example, this effectively makes the
  # resource read-only:
  self.excluded_actions = [:create, :update, :destroy, :update_all, :destroy_all]
end
```

### Routing

Use `rest_route` for non-resourceful controllers, or `rest_resource` / `rest_resources` resourceful
routers. These routers add some features to the Rails builtin `resource`/`resources` routers, such
as automatically routing extra actions defined on the controller. To route the root, use
`rest_root`.

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
the usual commands (e.g., `rails test`, `rails console`). For development, use `bin/dev` to run the
web server and the job queue, which serves the test app and coverage/brakeman reports:

- Test App: [http://127.0.0.1:3000](http://127.0.0.1:3000)
- API: [http://127.0.0.1:3000/api](http://127.0.0.1:3000/api)
- Reports: [http://127.0.0.1:3000/reports](http://127.0.0.1:3000/reports)
