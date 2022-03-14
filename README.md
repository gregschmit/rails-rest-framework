# Rails REST Framework

[![Gem Version](https://badge.fury.io/rb/rest_framework.svg)](https://badge.fury.io/rb/rest_framework)
[![Build Status](https://travis-ci.com/gregschmit/rails-rest-framework.svg?branch=master)](https://travis-ci.com/gregschmit/rails-rest-framework)
[![Coverage Status](https://coveralls.io/repos/github/gregschmit/rails-rest-framework/badge.svg?branch=master)](https://coveralls.io/github/gregschmit/rails-rest-framework?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/ba5df7706cb544d78555/maintainability)](https://codeclimate.com/github/gregschmit/rails-rest-framework/maintainability)

A framework for DRY RESTful APIs in Ruby on Rails.

**The Problem**: Building controllers for APIs usually involves writing a lot of redundant CRUD
logic, and routing them can be obnoxious. Building and maintaining features like ordering,
filtering, and pagination can be tedious.

**The Solution**: This framework implements browsable API responses, CRUD actions for your models,
and features like ordering/filtering/pagination, so you can focus on building awesome APIs.

Website/Guide: [https://rails-rest-framework.com](https://rails-rest-framework.com)

Source: [https://github.com/gregschmit/rails-rest-framework](https://github.com/gregschmit/rails-rest-framework)

YARD Docs: [https://rubydoc.info/gems/rest_framework](https://rubydoc.info/gems/rest_framework)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rest_framework'
```

And then execute:

```shell
$ bundle install
```

Or install it yourself with:

```shell
$ gem install rest_framework
```

## Quick Usage Tutorial

### Controller Mixins

To transform a controller into a RESTful controller, you can either include `BaseControllerMixin`,
`ReadOnlyModelControllerMixin`, or `ModelControllerMixin`. `BaseControllerMixin` provides a `root`
action and a simple interface for routing arbitrary additional actions:

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  self.extra_actions = {test: [:get]}

  def test
    render inline: "Test successful!"
  end
end
```

`ModelControllerMixin` assists with providing the standard model CRUD for your controller.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.recordset = Movie.where(enabled: true)
end
```

`ReadOnlyModelControllerMixin` only enables list/show actions, but since we're naming this
controller in a way that doesn't make the model obvious, we can set that explicitly:

```ruby
class Api::ReadOnlyMoviesController < ApiController
  include RESTFramework::ReadOnlyModelControllerMixin

  self.model = Movie
end
```

Note that you can also override the `get_recordset` instance method to override the API behavior
dynamically per-request.

### Routing

You can use Rails' `resource`/`resources` routers to route your API, however if you want
`extra_actions` / `extra_member_actions` to be routed automatically, then you can use `rest_route`
for non-resourceful controllers, or `rest_resource` / `rest_resources` resourceful routers. You can
also use `rest_root` to route the root of your API:

```ruby
Rails.application.routes.draw do
  rest_root :api  # will find `api_controller` and route the `root` action to '/api'
  namespace :api do
    rest_resources :movies
    rest_resources :users
  end
end
```

Or if you want the API root to be routed to `Api::RootController#root`:

```ruby
Rails.application.routes.draw do
  namespace :api do
    rest_root  # will route `Api::RootController#root` to '/' in this namespace ('/api')
    rest_resources :movies
    rest_resources :users
  end
end
```

## Development/Testing

After you clone the repository, cd'ing into the directory should create a new gemset if you are
using RVM. Then run `bundle install` to install the appropriate gems.

To run the test suite:

```shell
$ rails test
```

The top-level `bin/rails` proxies all Rails commands to the test project, so you can operate it via
the usual commands. Ensure you run `rails db:setup` before running `rails server` or
`rails console`.
