require_relative "../base_crud"

class PlainApi::ThingsControllerTest < ActionController::TestCase
  include BaseCRUD

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}
end
