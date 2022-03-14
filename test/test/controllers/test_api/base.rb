require "test_helper"

module BaseTestApiControllerTests
  def self.included(base)
    base.setup { Rails.application.load_seed }
  end
end
