require_relative 'base'


class Api1::ThingsControllerTest < ActionController::TestCase
  include BaseApi1ControllerTests
  self.create_params = {name: "quicktest"}
  self.update_params = {name: "quicktest"}
end
