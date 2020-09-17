# REST Framework

REST Framework helps you build awesome APIs in Ruby on Rails.

**The Problem**: Building controllers for APIs usually involves writing a lot of redundant CRUD
logic, and routing them can be obnoxious.

**The Solution**: This gem handles the common logic so you can focus on the parts of your API which
make it unique.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rest_framework'
```

And then execute:

    $ bundle install

Or install it yourself with:

    $ gem install rest_framework

## Usage

### Controller Mixins

To transform a controller into a RESTful controller, you can either include `BaseControllerMixin`,
`ReadOnlyModelControllerMixin`, or `ModelControllerMixin`. `BaseControllerMixin` provides a `root`
action and a simple interface for routing arbitrary additional actions:

```
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  @extra_actions = {test: [:get]}

  def test
    render inline: "Test successful!"
  end
end
```

`ModelControllerMixin` assists with providing the standard CRUD for your controller.

```
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  @recordset = Movie.where(enabled: true)  # by default, @recordset would include all movies
end
```

`ReadOnlyModelControllerMixin` only enables list/show actions, but since we're naming this
controller in a way that doesn't make the model obvious, we can set that explicitly:

```
class Api::ReadOnlyMoviesController < ApiController
  include RESTFramework::ReadOnlyModelControllerMixin

  @model = Movie
end
```

Note that you can also override `get_model` and `get_recordset` instance methods to override the API
behavior based on each request.

### Routing

You can use Rails' `resource`/`resources` routers to route your API, however if you want
`@extra_actions`/`@extra_member_actions` to be routed automatically, then you can use the
`rest_resource`/`rest_resources` routers provided by this gem. You can also use `rest_root` to route
the root of your API:

```
Rails.application.routes.draw do
  rest_root :api  # will find `api_controller` and route the `root` action to '/api'
  namespace :api do
    rest_resources :movies
    rest_resources :read_only_movies
  end
end
```

Or if you want the API root to be routed to `Api::RootController#root`:

```
Rails.application.routes.draw do
  namespace :api do
    rest_root  # will route `Api::RootController#root` to '/' in this namespace ('/api')
    rest_resources :movies
    rest_resources :read_only_movies
  end
end
```

## Development/Testing

After you clone the repository, cd'ing into the directory should create a new gemset if you are
using RVM. Then run `bundle install` to install the appropriate gems.

To run the full test suite:

    $ rake test

To run unit tests:

    $ rake test:unit

To run integration tests:

    $ rake test:integration

To interact with the integration app, you can `cd test/integration` and operate it via the normal
Rails interfaces. Ensure you run `rake db:schema:load` before running `rails server` or
`rails console`.
