---
layout: default
---
# Rails REST Framework Documentation

[![Gem Version](https://badge.fury.io/rb/rest_framework.svg)](https://badge.fury.io/rb/rest_framework)
[![Build Status](https://travis-ci.org/gregschmit/rails-rest-framework.svg?branch=master)](https://travis-ci.org/gregschmit/rails-rest-framework)

Rails REST Framework helps you build awesome Web APIs in Ruby on Rails.

**The Problem**: Building controllers for APIs usually involves writing a lot of redundant CRUD
logic, and routing them can be obnoxious.

**The Solution**: This gem handles the common logic so you can focus on the parts of your API which
make it unique.

Website: https://rails-rest-framework.com

Source: https://github.com/gregschmit/rails-rest-framework

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

To run the test suite:

```shell
$ rake test
```

To interact with the test app, `cd test` and operate it via the normal Rails interfaces. Ensure you
run `rake db:schema:load` before running `rails server` or `rails console`. You can also load the
test fixtures with `rake db:fixtures:load`.
