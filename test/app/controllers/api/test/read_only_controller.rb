class Api::Test::ReadOnlyController < Api::TestController
  self.model = User
  self.excluded_actions = [ :create, :update, :destroy, :update_all, :destroy_all ]

  class SingularManagerSerializer < RESTFramework::NativeSerializer
    self.config = { only: [ :login, :age, :balance ] }
  end

  self.native_serializer_config = { include: { manager: { only: [ :login, :age, :balance ] } } }
  self.native_serializer_singular_config = {
    include: { manager: SingularManagerSerializer },
    methods: [ :calculated_property ],
  }
end
