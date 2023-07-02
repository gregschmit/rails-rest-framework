require_relative "base"

class Api::Demo::MoviesControllerTest < ActionController::TestCase
  include Api::Demo::Base

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}

  if defined?(Ransack)
    def test_ransack_simple
      get(:index, as: :json, params: {q: {price_gt: 15}})
      assert_response(:success)
      assert_equal(1, @response.parsed_body["results"].length)
    end
  end
end
