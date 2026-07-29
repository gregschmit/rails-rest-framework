# A straightforward model controller that inherits `paginator_class = nil` from the test API base,
# exercising the `index` code path that skips pagination (returning a bare array). Migrated from the
# removed plain API, which was the only API whose controllers ran without a paginator.
class Api::Test::UnpaginatedController < Api::TestController
  self.model = User
end
