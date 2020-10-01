---
layout: default
title: Controller Mixins
---
# Controller Mixins

This is the core of the REST framework. Generally speaking, projects already have an existing
controller inheritance hierarchy. Also, it's helpful to define controller functionality at the
individual API controllers. For these reasons, REST framework provides the controller functionality
as modules that you mixin to your controllers.

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

Note that you can also override `get_model` and `get_recordset` instance methods to override the API
behavior dynamically per-request.
