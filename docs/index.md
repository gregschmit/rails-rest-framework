---
layout: default
---
# Rails REST Framework Documentation

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
