require_relative "base"

class DemoApi::UsersControllerTest < ActionController::TestCase
  include BaseDemoApiControllerTests

  self.create_params = {login: "mutation_test"}
  self.update_params = {login: "mutation_test"}
end
