require_relative "base_crud"

class PlainApi::UsersControllerTest < ActionController::TestCase
  include PlainApi::BaseCRUD

  self.create_params = {login: "mutation_test"}
  self.update_params = {login: "mutation_test"}
end
