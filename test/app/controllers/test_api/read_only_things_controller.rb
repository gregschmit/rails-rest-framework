class TestApi::ReadOnlyThingsController < TestApiController
  include RESTFramework::ReadOnlyModelControllerMixin

  class SingularOwnerSerializer < RESTFramework::NativeSerializer
    self.config = {only: [:login, :age, :balance]}
  end

  self.model = Thing
  self.native_serializer_config = {include: {owner: {only: [:login, :age, :balance]}}}
  self.native_serializer_singular_config = {
    include: {owner: SingularOwnerSerializer},
    methods: [:calculated_property],
  }
end
