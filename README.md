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

## Development/Testing

After you clone the repository, cd'ing into the directory should create a new gemset if you are
using RVM. Then run `bundle install` to install the appropriate gems.

To run the full test suite:

    $ rake test

To run unit tests:

    $ rake test:unit

To run integration tests on a sample app:

    $ rake test:app

To run that sample app live:

    $ rake test:app:run
