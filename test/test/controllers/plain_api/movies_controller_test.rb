require_relative "base_crud"

class PlainApi::MoviesControllerTest < ActionController::TestCase
  include PlainApi::BaseCRUD

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}
end
