class Api::Test::StarsController < Api::TestController
  self.model = Star

  # `starrable` is a polymorphic `belongs_to` (a `Movie` or a `Genre`); `user` is a regular one.
  self.fields = %w[id user starrable]
end
