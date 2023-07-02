require_relative "base"

class Api::Demo::MoviesControllerTest < ActionController::TestCase
  include Api::Demo::Base

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}
end
