class Api::Test::ReadOnlyController < Api::TestController
  self.model = User
  remove_collection_actions(:create, :update_all, :destroy_all)
  remove_member_actions(:update, :destroy)

  class SingularManagerSerializer < RESTFramework::NativeSerializer
    self.config = { only: [ :login, :age, :balance ] }
  end

  self.native_serializer_config = { include: { manager: { only: [ :login, :age, :balance ] } } }
  self.native_serializer_singular_config = {
    include: { manager: SingularManagerSerializer },
    methods: [ :calculated_property ],
  }
end
