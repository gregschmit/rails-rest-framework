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

  def test_bulk_create
    post(
      :create,
      as: :json,
      params: {_json: [{name: "test_bulk_1"}, {name: "test_bulk_2"}]},
    )
    assert_response(:success)
    assert(@response.parsed_body.all? { |r| Movie.find(r["id"]) })
  end

  def test_bulk_create_with_error
    post(
      :create,
      as: :json,
      params: {_json: [{name: "test_bulk_1"}, {name: "test_bulk_1"}]},
    )
    assert_response(:success)
    parsed_body = @response.parsed_body
    assert(Movie.find(parsed_body[0]["id"]))
    assert_nil(parsed_body[0]["errors"])
    assert_nil(parsed_body[1]["id"])
    assert(parsed_body[1]["errors"])
  end

  def test_bulk_update
    movie1 = Movie.create!(name: "test_bulk_1", price: 4)
    movie2 = Movie.create!(name: "test_bulk_2", price: 23)
    old_count = Movie.count

    patch(
      :update_all,
      as: :json,
      params: {_json: [{id: movie1.id, price: 5}, {id: movie2.id, price: 24}]},
    )
    assert_response(:success)

    movie1.reload
    movie2.reload
    assert_equal(5, movie1.price)
    assert_equal(24, movie2.price)
    assert_equal(old_count, Movie.count)
  end

  def test_bulk_update_with_error
    movie1 = Movie.create!(name: "test_bulk_1", price: 4)
    movie2 = Movie.create!(name: "test_bulk_2", price: 23)
    old_count = Movie.count

    patch(
      :update_all,
      as: :json,
      params: {_json: [{id: movie1.id, price: 5}, {id: movie2.id, price: 24, name: nil}]},
    )
    assert_response(:success)
    parsed_body = @response.parsed_body
    assert_nil(parsed_body[0]["errors"])
    assert(parsed_body[1]["errors"])

    movie1.reload
    movie2.reload
    assert_equal(5, movie1.price)
    assert_equal(23, movie2.price)
    assert_equal(old_count, Movie.count)
  end

  def test_bulk_destroy
    movie_names = ["Test Movie 1", "Test Movie 2"]
    movie_names.each { |n| Movie.create!(name: n) }
    movies = Movie.where(name: movie_names)
    assert_equal(2, movies.count)
    delete(:destroy_all, as: :json, params: {_json: movies.pluck(:id)})
    assert_response(:success)
    assert_equal(0, movies.count)
  end

  def test_bulk_destroy_validation_error
    movie_names = ["Test Movie 1", "Undestroyable"]
    movie_names.each { |n| Movie.create!(name: n) }
    movies = Movie.where(name: movie_names)
    assert_equal(2, movies.count)
    delete(:destroy_all, as: :json, params: {_json: movies.pluck(:id)})
    assert_response(:success)
    parsed_body = @response.parsed_body
    assert_equal(2, parsed_body.count)
    assert_nil(parsed_body[0]["errors"])
    assert(parsed_body[1]["errors"])
    assert_equal(1, movies.count)
  end
end
