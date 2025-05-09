class Api::Test::ReadOnlyController < Api::TestController
  include RESTFramework::ReadOnlyModelControllerMixin

  class SingularManagerSerializer < RESTFramework::NativeSerializer
    self.config = { only: [ :login, :age, :balance ] }
  end

  self.model = User
  self.native_serializer_config = { include: { manager: { only: [ :login, :age, :balance ] } } }
  self.native_serializer_singular_config = {
    include: { manager: SingularManagerSerializer },
    methods: [ :calculated_property ],
  }
end
