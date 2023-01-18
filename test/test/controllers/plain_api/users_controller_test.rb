require_relative "base"

class PlainApi::UsersControllerTest < ActionController::TestCase
  include PlainApi::Base

  self.create_params = {login: "mutation_test"}
  self.update_params = {login: "mutation_test"}
end
