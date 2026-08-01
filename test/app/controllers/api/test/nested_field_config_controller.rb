class Api::Test::NestedFieldConfigController < Api::TestController
  self.model = User

  # `movies` is a collection association; its `field_config` shapes the movie fields, and the nested
  # `field_config` shapes the `genres` sub-association two levels deep (dropping `description`).
  self.fields = [ :id, :login, :movies ]
  self.field_config = {
    movies: {
      fields: [ :id, :name, :genres ],
      field_config: {
        genres: { fields: [ :id, :name ] },
      },
    },
  }
end
