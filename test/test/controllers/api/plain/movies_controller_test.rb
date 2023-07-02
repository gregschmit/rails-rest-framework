require_relative "base"

class Api::Plain::MoviesControllerTest < ActionController::TestCase
  include Api::Plain::Base

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}
end
