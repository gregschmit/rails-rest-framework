---
layout: default
---
# Rails REST Framework Documentation

[![Gem Version](https://badge.fury.io/rb/rest_framework.svg)](https://badge.fury.io/rb/rest_framework)
[![Build Status](https://travis-ci.org/gregschmit/rails-rest-framework.svg?branch=master)](https://travis-ci.org/gregschmit/rails-rest-framework)

Rails REST Framework helps you build awesome Web APIs in Ruby on Rails.

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

## Development/Testing

After you clone the repository, cd'ing into the directory should create a new gemset if you are
using RVM. Then run `bundle install` to install the appropriate gems.

To run the full test suite:

```shell
$ rake test
```

To run unit tests:

```shell
$ rake test:unit
```

To run integration tests:

```shell
$ rake test:integration
```

To interact with the integration app, you can `cd test/integration` and operate it via the normal
Rails interfaces. Ensure you run `rake db:schema:load` before running `rails server` or
`rails console`.
