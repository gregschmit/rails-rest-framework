# Association expansion via an EXPLICIT per-association allowlist. `requestable_fields` takes
# priority over sibling discovery, so only these fields are requestable even though the sibling
# (`Api::Test::AssocExp::UsersController`) would allow more.
class Api::Test::AssocExp::UsersExplicitController < Api::TestController
  self.model = User
  self.fields = %w[id login manager]
  self.enable_association_queries = true
  self.field_config = { manager: { requestable_fields: %w[age] } }
end
