require_relative "base"

class Api::Plain::UsersControllerTest < ActionController::TestCase
  include Api::Plain::Base

  self.create_params = {login: "mutation_test"}
  self.update_params = {login: "mutation_test"}
end
