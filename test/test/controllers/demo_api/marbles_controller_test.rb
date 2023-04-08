require_relative "base"

class DemoApi::MarblesControllerTest < ActionController::TestCase
  include DemoApi::Base

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}

  def test_bulk_create
    post(
      :create,
      as: :json,
      params: {_json: [{name: "test_bulk_marble_1"}, {name: "test_bulk_marble_2"}]},
    )
    assert_response(:success)
    assert(@response.parsed_body.all? { |r| Marble.find(r["id"]) })
  end

  def test_bulk_create_with_error
    post(
      :create,
      as: :json,
      params: {_json: [{name: "test_bulk_marble_1"}, {name: "test_bulk_marble_1"}]},
    )
    assert_response(:success)
    parsed_body = @response.parsed_body
    assert(Marble.find(parsed_body[0]["id"]))
    assert_nil(parsed_body[0]["errors"])
    assert_nil(parsed_body[1]["id"])
    assert(parsed_body[1]["errors"])
  end
end
