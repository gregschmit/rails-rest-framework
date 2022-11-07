---
layout: default
title: Controller Mixins
position: 2
slug: controller-mixins
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
`BaseControllerMixin`, which provides a `root` action so it can be used at the API root.

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
`get_recordset()` method.

```ruby
class Api::CoolMoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.recordset = Movie.where(cool: true).order({id: :asc})
end
```

#### extra_member_actions

The `extra_member_actions` property allows you to define additional actions on individual records.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.extra_member_actions = {disable: :post}

  def disable
    @record = self.get_record  # REST Framework will rescue ActiveRecord::RecordNotFound

    # REST Framework will rescue ActiveRecord::RecordInvalid or ActiveRecord::RecordNotSaved
    @record.update!(enabled: false)

    return api_response(@record)
  end
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

#### native_serializer_config

These properties define the serializer configuration if you are using the native `ActiveModel`
serializer. You can also specify serializers for singular/plural

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.native_serializer_config = {
    only: [:id, :name],
    methods: [:active, :some_expensive_computed_property],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }

  # Or you could configure a default and a plural serializer:
  self.native_serializer_plural_config = {
    only: [:id, :name],
    methods: [:active],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }
  self.native_serializer_config = {
    only: [:id, :name],
    methods: [:active, :some_expensive_computed_property],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }

  # Or you could configure a default and a singular serializer:
  self.native_serializer_config = {
    only: [:id, :name],
    methods: [:active],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }
  self.native_serializer_singular_config = {
    only: [:id, :name],
    methods: [:active, :some_expensive_computed_property],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }
end
```

#### allowed_parameters / allowed_action_parameters

These properties define the permitted parameters to be used in the request body for create/update
actions. If you need different allowed parameters, then you can also override the
`get_create_params` or `get_update_params` methods.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.allowed_parameters = [:name]
end
```

#### create_from_recordset (default: `true`)

The `create_from_recordset` attribute (`true` by default) is a boolean to control the behavior in
the `create` action. If it is disabled, records will not be created from the filtered recordset, but
rather will be created directly from the model interface.

For example, if this is your controller:

```ruby
class Api::CoolMoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  def get_recordset
    return Movie.where(cool: true)
  end
end
```

Then if you hit the `create` action with the payload `{name: "Superman"}`, it will also set `cool`
to `true` on the new record, because that property is inherited from the recordset.

## ReadOnlyModelControllerMixin

`ReadOnlyModelControllerMixin` only enables list/show actions. In this example, since we're naming
this controller in a way that doesn't make the model obvious, we can set that explicitly:

```ruby
class Api::ReadOnlyMoviesController < ApiController
  include RESTFramework::ReadOnlyModelControllerMixin

  self.model = Movie
end
```
