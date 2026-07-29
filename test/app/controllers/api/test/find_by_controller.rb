class Api::Test::FindByController < Api::TestController
  self.model = User
  self.fields = %w[id login age balance calculated_property]
  self.filter_recordset_before_find = false
  remove_actions(:create, :update, :destroy, :update_all, :destroy_all)
end
