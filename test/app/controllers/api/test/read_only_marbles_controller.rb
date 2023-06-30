class Api::Test::ReadOnlyMarblesController < Api::TestController
  include RESTFramework::ReadOnlyModelControllerMixin

  class SingularOwnerSerializer < RESTFramework::NativeSerializer
    self.config = {only: [:login, :age, :balance]}
  end

  self.model = Marble
  self.native_serializer_config = {include: {user: {only: [:login, :age, :balance]}}}
  self.native_serializer_singular_config = {
    include: {user: SingularOwnerSerializer},
    methods: [:calculated_property],
  }
end
