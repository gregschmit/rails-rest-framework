require_relative "base"

class DemoApi::MarblesControllerTest < ActionController::TestCase
  include DemoApi::Base

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}
end
