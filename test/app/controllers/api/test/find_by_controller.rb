class Api::Test::FindByController < Api::TestController
  self.model = User
  self.fields = %w[id login age balance]
  self.find_by_fields = %w[login]
  self.filter_recordset_before_find = false
  self.excluded_actions = [:create, :update, :destroy, :update_all, :destroy_all]
end
