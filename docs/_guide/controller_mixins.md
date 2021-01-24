---
layout: default
title: Controller Mixins
---
# Controller Mixins

This is the core of the REST Framework. Generally speaking, projects already have an existing
controller inheritance hierarchy, so we want developers to be able to maintain that project
structure while leveraging the power of the REST Framework. Also, different controllers which
inherit from the same parent often need different REST Framework mix-ins. For these reasons, REST
Framework provides the controller functionality as modules that you mix into your controllers.

## Response Rendering

Before we go into the various controller mixins, one of the core capabilities of the REST Framework
is to provide consistent, format-independent responses along side a browsable API. While you can use
Rails' builtin rendering tools, such as `render`, the REST Framework provides a rendering helper
called `api_response`. This helper allows you to return a browsable API response for the `html`
format which shows you what the JSON/XML response would look like, along with faster and lighter
responses for `json` and `xml` formats.

Here is an example:

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  self.extra_actions = {test: :get}

  def test
    api_response({message: "Test successful!"})
  end
end
```

## BaseControllerMixin

To transform a controller into the simplest possible RESTful controller, you can include
`BaseControllerMixin`, which provides a `root` action.

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
end
```

### Controller Attributes

You can customize the behavior of `BaseControllerMixin` by setting or mutating various class
attributes.

#### singleton_controller

This property primarily controls the routes that are generated for a RESTful controller. If you use
`api_resource`/`api_resources` to define whether the generates routes are for a collection or for
a single member, then you do not need to use this property. However, if you are autogenerating those
routers, then `singleton_controller` will tell REST Framework whether to provide collection routes
(when `singleton_controller` is falsy) or member routes (when `singleton_controller` is truthy). To
read more about singular vs plural routing, see Rails' documentation here:
https://guides.rubyonrails.org/routing.html#singular-resources.

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  self.extra_actions = {test: :get}

  def test
    api_response({message: "Test successful!"})
  end
end
```

#### extra_actions

This property defines extra actions on the controller to be routed. It is a hash of
`endpoint -> method(s)` (where `method(s)` can be a method symbol or an array of method symbols).

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  self.extra_actions = {test: :get}

  def test
    api_response({message: "Test successful!"})
  end
end
```

Or with multiple methods:

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  self.extra_actions = {test: [:get, :post]}

  def test
    api_response({message: "Test successful!"})
  end
end
```

#### skip_actions

You may want to skip some of the default actions provided by the router. `skip_actions` should be an
array (or iterable) which defines actions we should skip. Here is an example of that:

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  self.skip_actions = [:show, :destroy]
end
```

[//]: <> TODO: ### Controller Methods (explain method overrides)

## ModelControllerMixin

`ModelControllerMixin` assists with providing the standard model CRUD (create, read, update,
destroy) for your controller. This is the most commonly used mixin since it provides default
behavior which matches Rails' default routing.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin
end
```

### Controller Attributes

You can customize the behavior of `ModelControllerMixin` by setting or mutating various class
attributes.

#### model

The `model` property allows you to define the model if it is not obvious from the controller name.

```ruby
class Api::CoolMoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.model = Movie
end
```

#### recordset

The `recordset` property allows you to define the set of records this API should be limited to. If
you need to change the recordset based on properties of the request, then you can override the
`get_recordset` method.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.recordset = Movie.where(enabled: true).order()
end
```

#### fields

The `fields` property defines the default fields for serialization and for parameters allowed from
the body or query string.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.fields = [:id, :name]
end
```

#### action_fields

The `action_fields` property is similar to `fields`, but allows you to define different fields for
different actions. A good example is to serialize expensive computed properties only in the `show`
action, but not in the `list` action (where many records are serialized).

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.fields = [:id, :name]
  self.action_fields = {
    show: [:id, :name, :some_expensive_computed_property],
  }
end
```

#### native_serializer_config / native_serializer_action_config

These properties define the serializer configuration if you are using the native Ruby on Rails
serilizer, either globally or per-action.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.native_serializer_config = {
    only: [:id, :name],
    methods: [:active, :some_expensive_computed_property],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }
end
```

#### filterset_fields

Basic filtering is supported by the `ModelControllerMixin`, and the `filterset_fields` property
allows you to define which fields are allowed to be filtered against.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.filterset_fields = [:id, :name]
end
```

[//]: <> TODO: #### allowed_parameters

[//]: <> TODO: #### allowed_action_parameters

[//]: <> TODO: #### serializer_class

[//]: <> TODO: #### extra_member_actions

[//]: <> TODO: #### disable_creation_from_recordset

[//]: <> TODO: ### Controller Methods (explain method overrides)

## ReadOnlyModelControllerMixin

`ReadOnlyModelControllerMixin` only enables list/show actions. In this example, since we're naming
this controller in a way that doesn't make the model obvious, we can set that explicitly:

```ruby
class Api::ReadOnlyMoviesController < ApiController
  include RESTFramework::ReadOnlyModelControllerMixin

  self.model = Movie
end
```
