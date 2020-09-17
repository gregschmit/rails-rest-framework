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

To transform a controller into a RESTful controller, you can either include `BaseControllerMixin` or
`ModelControllerMixin`. `BaseControllerMixin` provides a `root` action and a simple interface for
routing arbitrary additional actions:

```
class Api1Controller < ActionController::Base
  include RESTFramework::ModelControllerMixin

  def root
    render inline: "This is the root of your API!"
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
