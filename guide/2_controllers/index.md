# Controllers

This is the core of the REST Framework. Generally speaking, projects already have an existing
controller inheritance hierarchy, so we want developers to be able to maintain that project
structure while leveraging the power of the REST Framework. Also, different controllers which
inherit from the same parent often need different REST Framework functionality and behavior. For
these reasons, REST Framework provides the controller functionality as modules that you mix into
your controllers.

Here is a graph of the controller mixins (all exist within the `RESTFramework` namespace), with
supplementary mixins shown as well:

```shell
BaseControllerMixin
BaseModelControllerMixin (includes BaseControllerMixin)
ModelControllerMixin (includes BaseModelControllerMixin)
├── ListModelMixin
├── ShowModelMixin
├── CreateModelMixin
├── UpdateModelMixin
└── DestroyModelMixin
ReadOnlyModelControllerMixin (includes BaseModelControllerMixin)
├── ListModelMixin
└── ShowModelMixin
BulkModelControllerMixin (includes ModelControllerMixin)
├── BulkCreateModelMixin
├── BulkUpdateModelMixin
└── BulkDestroyModelMixin
```

All API controllers should include at least one of these top-level controller mixins, and can
include any of the supplementary mixins to add additional functionality. For example, if you want to
permit create but not update or destroy, then you could do this:

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::BaseModelControllerMixin
  include RESTFramework::CreateModelMixin
end
```

## BaseControllerMixin

To transform a controller into the simplest possible RESTful controller, you can include
`BaseControllerMixin`, which provides a simple `root` action so it can be used at the API root.

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
end
```

### Response Rendering

A fundamental feature that REST Framework provides is the ability to render a browsable API. This
allows developers to discover and interact with the API's functionality, while also providing faster
and more lightweight JSON/XML formats for consumption by the systems these developers create.

The `api_response` method is how this is accomplished. The first argument is the data to be
rendered (often an array or hash), and keyword arguments can be provided to customize the response
(e.g., setting the HTTP status code). Using this method instead of the classic Rails helpers, such
as `render`, will automatically provide the browsable API as well as JSON/XML rendering.

Here is a simple example of rendering a hash with a `message` key:

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
  self.extra_actions = {test: :get}

  def test
    api_response({message: "Test successful!"})
  end
end
```

### Routing Extra Actions

The `extra_actions` property defines extra actions on the controller to be routed. It is a hash of
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

If your action conflicts with a builtin method, then you can also override the path:

```ruby
class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  # This will route `test_action` to `/test`, in case there is already a `test` method that cannot
  # be overridden.
  self.extra_actions = {test_action: {path: :test, methods: :get}}

  def test_action
    api_response({message: "Test successful!"})
  end
end
```

## ModelControllerMixin

`ModelControllerMixin` assists with providing the standard model CRUD (create, read, update,
destroy) for your controller. This is the most commonly used mixin since it provides default
behavior for models which matches Rails' resourceful routing.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin
end
```

By default, all columns and associations are included in the controller's `fields`, which can be
helpful when developing an administrative API. For most APIs, however, `fields` should be explicitly
defined. See [Specifying the Fields](#specifying-the-fields) for more information.

### Defining the Model

The `model` property allows you to define the model if it is not derivable from the controller name.

```ruby
class Api::CoolMoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.model = Movie
end
```

### Specifying the Recordset

The `recordset` property allows you to define the set of records this API should be limited to. If
you need to change the recordset based on properties of the request, then you can override the
`get_recordset` method.

```ruby
class Api::CoolMoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.recordset = Movie.where(cool: true).order({id: :asc})
end
```

If you override `get_recordset`, you should ensure you also set the `model` property if it's not
derivable from the controller name.

```ruby
class Api::CoolMoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.model = Movie

  def get_recordset
    return Movie.where(cool: true).order({id: :asc})
  end
end
```

### Specifying Extra Member Actions

While `extra_actions` (and the synonym `extra_collection_actions`) allows you to define additional
actions on the controller, `extra_member_actions` allows you to define additional member actions on
the controller, which require a record ID to be provided as a path param.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.extra_member_actions = {disable: :patch}

  def disable
    # REST Framework will rescue ActiveRecord::RecordNotFound.
    @record = self.get_record

    # REST Framework will rescue ActiveRecord::RecordInvalid or ActiveRecord::RecordNotSaved.
    @record.update!(enabled: false)

    return api_response(@record)
  end
end
```

### Specifying the Fields

The `fields` property defines the fields available for things like serialization and allowed
parameters in body or query params. If `fields` is not set, then it will default to all columns and
associations, which is helpful when developing an administrative API. For most APIs, however,
`fields` should be explicitly defined.

While you can also define per-request fields by overriding `get_fields`, you should also define a
set of fields on the controller which is used for things like the `OPTIONS` metadata.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.fields = [:id, :name]
end
```

You can also mutate the default set of fields by removing existing columns/associations, and even
adding methods. The framework will automatically detect if the given field is a column, association,
 or method, and will handle it appropriately.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  # This will include all columns, all associations except `owners`, and the `is_featured` method.
  self.fields = {
    exclude: [:owners],
    include: [:is_featured],
  }
end
```

### Specifying the Serializer Configuration

For most cases, the default serializer configuration is sufficient, and can be modified by adjusting
the `fields` property on the controller. However, there are cases where you may want to define a
serializer configuation, such as when you want to customize nested associations, or if you want to
remove certain fields (like methods) when serializing multiple records.

The property  `native_serializer_config` defines the serializer configuration if you are using the
default serializer. You can also specify serializers for singular/plural data.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.native_serializer_config = {
    only: [:id, :name],
    methods: [:active, :some_expensive_computed_property],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }

  # Or you could configure a default and a plural serializer:
  self.native_serializer_config = {
    only: [:id, :name],
    methods: [:active, :some_expensive_computed_property],
    include: {cast_members: { only: [:id, :name], methods: [:net_worth] }},
  }
  self.native_serializer_plural_config = {
    only: [:id, :name],
    methods: [:active],
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

### Specifying Allowed Parameters

The `allowed_parameters` property defines the allowed parameters for create/update actions. The
framework uses strong parameters to execute this filtering.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.allowed_parameters = [:name]
end
```

If you want different allowed parameters for create/update actions, or if you need stronger control
over what request body parameters get passed to create/update, then you can also override the
`get_create_params` or `get_update_params` methods.

### Controlling Create Behavior

The `create_from_recordset` attribute (`true` by default) is a boolean to control the behavior in
the `create` action. If it is disabled, records will not be created from the filtered recordset, but
rather will be created directly from the model interface.

For example, if this is your controller:

```ruby
class Api::CoolMoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  # Notice that `cool` is read-only with the following two configurations:
  self.fields = [:id, :name]
  self.native_serializer_config = {only: [:id, :name, :cool]}

  # New records created from this controller will have `cool` set to `true`.
  def get_recordset
    return Movie.where(cool: true)
  end
end
```

Then if you hit the `create` action with the payload `{name: "Superman"}`, it will also set `cool`
to `true` on the new record, because that property is inherited from the recordset.

## ReadOnlyModelControllerMixin

`ReadOnlyModelControllerMixin` only enables list/show actions.

```ruby
class Api::ReadOnlyMoviesController < ApiController
  include RESTFramework::ReadOnlyModelControllerMixin

  self.model = Movie
end
```
