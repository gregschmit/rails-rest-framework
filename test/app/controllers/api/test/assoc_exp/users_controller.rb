# Sibling-discovery case: `manager` is self-referential, so the sibling for `User` is this
# controller. `is_admin` (write_only) must never be pullable; `balance` (hidden) must be requestable.
class Api::Test::AssocExp::UsersController < Api::TestController
  self.model = User
  self.fields = %w[id login age balance is_admin manager]
  self.write_only_fields = %w[is_admin]
  self.field_config = { balance: { hidden: true } }
  self.enable_association_queries = true
end
