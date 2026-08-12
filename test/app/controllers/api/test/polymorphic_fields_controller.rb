class Api::Test::PolymorphicFieldsController < Api::TestController
  self.model = User

  # `favorite` is a polymorphic `belongs_to` (a `Movie` or a `Genre`). Configuring extra fields must
  # serialize them per-target: `price` exists on `Movie` but not `Genre`, so it is omitted there.
  # `id`/`type` are omitted here on purpose — they always identify a polymorphic ref, so they are
  # emitted regardless of the configured fields.
  self.fields = %w[id login favorite]
  self.field_config = {
    favorite: { fields: [ :name, :price ] },
  }
end
