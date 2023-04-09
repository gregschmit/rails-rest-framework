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

  def test_bulk_update
    marble1 = Marble.create!(name: "test_bulk_marble_1", radius_mm: 4)
    marble2 = Marble.create!(name: "test_bulk_marble_2", radius_mm: 23)
    old_count = Marble.count

    patch(
      :update_all,
      as: :json,
      params: {_json: [{id: marble1.id, radius_mm: 5}, {id: marble2.id, radius_mm: 24}]},
    )
    assert_response(:success)

    marble1.reload
    marble2.reload
    assert_equal(5, marble1.radius_mm)
    assert_equal(24, marble2.radius_mm)
    assert_equal(old_count, Marble.count)
  end

  def test_bulk_update_with_error
    marble1 = Marble.create!(name: "test_bulk_marble_1", radius_mm: 4)
    marble2 = Marble.create!(name: "test_bulk_marble_2", radius_mm: 23)
    old_count = Marble.count

    patch(
      :update_all,
      as: :json,
      params: {_json: [{id: marble1.id, radius_mm: 5}, {id: marble2.id, radius_mm: 24, name: nil}]},
    )
    assert_response(:success)
    parsed_body = @response.parsed_body
    assert_nil(parsed_body[0]["errors"])
    assert(parsed_body[1]["errors"])

    marble1.reload
    marble2.reload
    assert_equal(5, marble1.radius_mm)
    assert_equal(23, marble2.radius_mm)
    assert_equal(old_count, Marble.count)
  end

  def test_bulk_destroy
    marble_names = ["Example Marble 1", "Example Marble 2"]
    marbles = Marble.where(name: marble_names)
    assert_equal(2, marbles.count)
    delete(:destroy_all, as: :json, params: {_json: marbles.pluck(:id)})
    assert_response(:success)
    assert_equal(0, marbles.count)
  end

  def test_bulk_destroy_validation_error
    Marble.create!(name: "Undestroyable")
    marble_names = ["Example Marble 1", "Undestroyable"]
    marbles = Marble.where(name: marble_names)
    assert_equal(2, marbles.count)
    delete(:destroy_all, as: :json, params: {_json: marbles.pluck(:id)})
    assert_response(:success)
    parsed_body = @response.parsed_body
    assert_equal(2, parsed_body.count)
    assert_nil(parsed_body[0]["errors"])
    assert(parsed_body[1]["errors"])
    assert_equal(1, marbles.count)
  end
end
