class Api::Test::FieldsHashExcludeController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = {exclude: [:main_movies]}
  self.model = Genre
end
