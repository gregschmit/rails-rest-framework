class Api2::ReadOnlyThingsController < Api2Controller
  include RESTFramework::ReadOnlyModelControllerMixin

  self.model = Thing
  self.native_serializer_config = {include: {owner: {only: [:login, :age, :balance]}}}
  self.native_serializer_singular_config = {
    include: {owner: {only: [:login, :age, :balance]}},
    methods: [:calculated_property],
  }
end
