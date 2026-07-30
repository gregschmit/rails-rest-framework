# Per-association record limits. `managed_users` is a collection association; a consumer may set
# `?associations.managed_users.limit=N` or `all`, both capped at `association_limit_max`.
class Api::Test::AssocExp::LimitsController < Api::TestController
  self.model = User
  self.fields = %w[id login managed_users]
  self.enable_association_queries = true
  self.association_limit = 2
  self.association_limit_max = 5
end
