class Api::Test::BareCreateController < Api::TestController
  self.model = Movie
  self.fields = %w[id name]
  remove_actions(:index, :show, :update, :destroy)
  self.create_from_recordset = false
end
