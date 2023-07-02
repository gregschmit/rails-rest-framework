require "test_helper"

module BaseApi
  module TestControllerTests
    def self.included(base)
      base.setup { Rails.application.load_seed }
    end
  end
end
