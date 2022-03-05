require_relative 'base'

class DemoApi::UsersControllerTest < ActionController::TestCase
  include BaseDemoApiControllerTests
  self.create_params = {login: "quicktest"}
  self.update_params = {login: "quicktest"}
end
