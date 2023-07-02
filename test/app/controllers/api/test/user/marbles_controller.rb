class Api::Test::User::MarblesController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)

  def get_recordset
    return User.first!.marbles
  end
end
