require_relative "base"

class PlainApi::MoviesControllerTest < ActionController::TestCase
  include PlainApi::Base

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}
end
