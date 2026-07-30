# Per-association `nil` overrides: `limit: nil` makes the default unlimited, and
# `limit_max: nil` lets a consumer request unlimited via `limit=all`.
class Api::Test::AssocExp::LimitsUnlimitedController < Api::TestController
  self.model = User
  self.fields = %w[id login managed_users]
  self.enable_association_queries = true
  self.association_limit = 2
  self.field_config = { managed_users: { limit: nil, limit_max: nil } }
end
