# The default limit still bounds responses when `enable_association_queries` is off, but the
# `?associations.<name>.limit=…` param is ignored.
class Api::Test::AssocExp::LimitsDisabledController < Api::TestController
  self.model = User
  self.fields = %w[id login managed_users]
  self.association_limit = 2
end
