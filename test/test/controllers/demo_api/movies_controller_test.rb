require_relative "base_crud"

class DemoApi::MoviesControllerTest < ActionController::TestCase
  include DemoApi::BaseCRUD

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}
end
