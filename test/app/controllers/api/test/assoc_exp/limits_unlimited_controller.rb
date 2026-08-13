# Per-association `nil` overrides: `limit: nil` makes the default unlimited, and
# `limit_max: nil` lets a consumer request unlimited via `limit=all`.
class Api::Test::AssocExp::LimitsUnlimitedController < Api::TestController
  self.model = User
  self.fields = {
    only: %w[id login managed_users],
    config: { managed_users: { limit: nil, limit_max: nil } },
  }
  self.enable_association_queries = true
  self.association_limit = 2
end
