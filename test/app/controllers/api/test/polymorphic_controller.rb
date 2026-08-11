class Api::Test::PolymorphicController < Api::TestController
  self.model = User

  # `favorite` is a polymorphic `belongs_to` (a `Movie` or a `Genre`).
  self.fields = %w[id login favorite]
end
