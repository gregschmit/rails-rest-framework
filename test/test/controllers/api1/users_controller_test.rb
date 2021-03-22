require_relative 'base'


class Api1::UsersControllerTest < ActionController::TestCase
  include BaseApi1ControllerTests
  self.create_params = {login: "quicktest"}
  self.update_params = {login: "quicktest"}
end
