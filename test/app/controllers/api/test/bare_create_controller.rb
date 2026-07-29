class Api::Test::BareCreateController < Api::TestController
  self.model = Movie
  self.fields = %w[id name]
  remove_collection_action(:index)
  remove_member_actions(:show, :update, :destroy)
  self.create_from_recordset = false
end
