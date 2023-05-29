class TestApi::GenresWithFieldsHashController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = {exclude: [:main_movies]}
  self.model = Genre
end
