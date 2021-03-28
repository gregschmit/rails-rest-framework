---
layout: default
title: Serializers
position: 3
slug: serializers
---
# Serializers

Serializers allow complex objects to be converted to Ruby primitives (`Array` and `Hash` objects),
which can then be converted to JSON or XML.

## NativeSerializer

This serializer uses Rails' native `ActiveModel::Serializers.serializable_hash` method to convert
records/recordsets to Ruby primitives (`Array` and `Hash`).

This is the default serializer, you can configure it using the controller class attributes
`native_serializer_config` (or `native_serializer_singular_config` /
`native_serializer_plural_config`):

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  self.native_serializer_config = {
    only: [:id, :name],
    methods: [:active, :some_expensive_computed_property],
    include: {cast_members: { only: [:id, :name] }},
  }
end
```

If you want to re-use a serializer, then you can define it as a standalone class, and you can even
nest them. You can also define separate configurations for serializing individual records vs
recordsets using `singular_config` and `plural_config`, respectively.

```ruby
class Api::MoviesController < ApiController
  include RESTFramework::ModelControllerMixin

  class CastMemberSerializer < RESTFramework::NativeSerializer
    self.config = { only: [:id, :name], methods: [:net_worth] }
    self.plural_config = { only: [:id, :name] }
  end

  class MovieSerializer < RESTFramework::NativeSerializer
    self.config = {
      only: [:id, :name],
      include: {cast_members: CastMemberSerializer.new(many: true)},
    }
    self.singular_config = {
      only: [:id, :name],
      methods: [:active, :some_expensive_computed_property],
      include: {cast_members: CastMemberSerializer.new(many: true)},
    }
  end

  self.serializer_class = MovieSerializer
end
```
