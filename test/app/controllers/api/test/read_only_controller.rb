class Api::Test::ReadOnlyController < Api::TestController
  self.model = User
  remove_actions(:create, :update, :destroy, :update_all, :destroy_all)

  class SingularManagerSerializer < RESTFramework::NativeSerializer
    self.config = { only: [ :login, :age, :balance ] }
  end

  # `config` is the default (used for collections here); `singular_config` adds detail on `show`.
  class Serializer < RESTFramework::NativeSerializer
    self.config = { include: { manager: { only: [ :login, :age, :balance ] } } }
    self.singular_config = {
      include: { manager: SingularManagerSerializer },
      methods: [ :calculated_property ],
    }
  end

  self.serializer_class = Serializer
end
