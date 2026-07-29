# Rails REST Framework

[![Gem Version](https://badge.fury.io/rb/rest_framework.svg)](https://badge.fury.io/rb/rest_framework)
[![Pipeline](https://github.com/gregschmit/rails-rest-framework/actions/workflows/pipeline.yml/badge.svg)](https://github.com/gregschmit/rails-rest-framework/actions/workflows/pipeline.yml)
[![Coverage](https://coveralls.io/repos/github/gregschmit/rails-rest-framework/badge.svg?branch=master)](https://coveralls.io/github/gregschmit/rails-rest-framework?branch=master)

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

  # Assignments are local by default; wrap shared config in `propagate` so child controllers inherit
  # it. A paginator set here makes more sense than defining it on every child controller.
  propagate do
    self.paginator_class = RESTFramework::PageNumberPaginator
    self.page_size = 30
  end
end
```

> **Note:** Configuration assignments are **local by default** — `self.x = value` sets `x` on that
> controller alone and does not propagate to subclasses. To share a setting with every descendant
> (pagination, filter backends, serializer config, and so on), wrap the assignment in a
> `propagate` block on a base controller.

Here is what the directory structure might look like for resource controllers:

```text
controllers/
├─ api_controller.rb
└─ api/
   ├─ movies_controller.rb
   └─ users_controller.rb
```

### Serving the Root API Index

A controller without a `model` renders its `index_content` at its index path, which serves as the
API root. Because declared actions are local by default (they don't propagate to subclasses), you
can serve the index — and any root-specific extra actions — straight from your API's base
controller:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  add_action(:test, :get)

  # Rendered at the `/api` root. Defaults to the controller's `description`.
  def index_content
    {
      message: "Welcome to the API.",
      how_to_authenticate: <<~END.lines.map(&:strip).join(" "),
        You can use this API with your normal login session. Otherwise, you can insert your API key
        into a Bearer Authorization header, or into the URL parameters with the name `api_key`.
      END
    }
  end

  def test
    render(api: {message: "Hello, world!"})
  end
end
```

### Resource Controllers

Other API controllers can be associated to a resource/model by setting `model`, e.g.
`self.model = Movie`.

```ruby
class Api::MoviesController < ApiController
  self.model = Movie  # Automatically routes the standard CRUD actions for this controller.
  self.bulk = true  # Enables bulk create/update/destroy actions for this controller.
  self.fields = [:id, :name, :release_date, :enabled]
  add_action(:first, :get, type: :member)

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
  # Include a method `popularity` and exclude the `impersonation_token` column.
  self.fields = {include: [:popularity], exclude: [:impersonation_token]}

  # You can even disable some of the builtin actions. For example, this effectively makes the
  # resource read-only:
  remove_actions(:create, :update, :destroy, :update_all, :destroy_all)
end
```

### Routing

Use `rest_route` to route any controller. It wraps Rails' `resource` / `resources` routers, picking
`resources` for a plural model controller and `resource` otherwise, and automatically routes the
controller's built-in and extra actions. A controller with a `model` gets the full CRUD set; a
modelless controller is routed at its root (its `index`, which renders `index_content`).

```ruby
Rails.application.routes.draw do
  rest_route :api  # `ApiController` serves the `/api` root.

  namespace :api do
    rest_route :movies
    rest_route :users
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
