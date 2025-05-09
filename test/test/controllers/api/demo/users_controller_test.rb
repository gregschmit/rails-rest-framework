require_relative "base"

class Api::Demo::UsersControllerTest < ActionController::TestCase
  include Api::Demo::Base

  self.create_params = { login: "mutation_test" }
  self.update_params = { login: "mutation_test" }
end
