# Secure-by-default: `enable_association_queries` is off (the default), so association-expansion
# query params are ignored entirely.
class Api::Test::AssocExp::UsersDisabledController < Api::TestController
  self.model = User
  self.fields = %w[id login age manager]
end
