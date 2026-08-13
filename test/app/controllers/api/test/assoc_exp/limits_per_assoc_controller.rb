# Per-association limit overrides via `field_config`: `managed_users` gets a smaller default and a
# lower cap, each overriding the controller-wide setting.
class Api::Test::AssocExp::LimitsPerAssocController < Api::TestController
  self.model = User
  self.fields = {
    only: %w[id login managed_users],
    config: {
      managed_users: { limit: 1, limit_max: 3 },
    },
  }
  self.enable_association_queries = true
  self.association_limit = 2
  self.association_limit_max = 5
end
