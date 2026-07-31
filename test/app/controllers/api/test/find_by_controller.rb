class Api::Test::FindByController < Api::TestController
  self.model = User
  # `legal_name` is a real column but write_only, so it must not be a lookup/filter/order surface.
  self.fields = %w[id login age balance calculated_property legal_name]
  self.write_only_fields = %w[legal_name]
  self.filter_recordset_before_find = false
  remove_actions(:create, :update, :destroy, :update_all, :destroy_all)
end
