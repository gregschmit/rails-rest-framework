class Api::Test::Nested::MoviesController < Api::TestController
  self.model = Movie

  # Stand-in for a permission scope: `nested_hidden` movies are not accessible. When `genres` is
  # nested under this controller, its auto-scoping looks the parent movie up through this recordset,
  # so a hidden movie's genres 404 (existence-hiding) rather than leaking.
  def get_recordset
    Movie.where.not(name: "nested_hidden")
  end
end
