class Api::Test::GenresWithFieldsHashController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = {exclude: [:main_movies]}
  self.model = Genre
end
