require_relative "base_crud"

class DemoApi::UsersControllerTest < ActionController::TestCase
  include DemoApi::BaseCRUD

  self.create_params = {login: "mutation_test"}
  self.update_params = {login: "mutation_test"}
end
