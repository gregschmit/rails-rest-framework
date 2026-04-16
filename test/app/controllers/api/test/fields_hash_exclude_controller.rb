class Api::Test::FieldsHashExcludeController < Api::TestController
  self.model = Genre
  self.fields = { exclude: [ :main_movies ] }
end
