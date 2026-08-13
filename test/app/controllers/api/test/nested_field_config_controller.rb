class Api::Test::NestedFieldConfigController < Api::TestController
  self.model = User

  # `movies` is a collection association; its `field_config` shapes the movie fields, and the nested
  # `field_config` shapes the `genres` sub-association two levels deep (dropping `description`).
  self.fields = {
    only: [ :id, :login, :movies ],
    config: {
      movies: {
        fields: {
          only: [ :id, :name, :genres ],
          config: {
            genres: { fields: [ :id, :name ] },
          },
        },
      },
    },
  }
end
