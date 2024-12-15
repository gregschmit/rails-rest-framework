ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"

# TODO: Get working? Not working now.
# Setup Bullet, if it's available.
# if defined?(Bullet)
#   module MiniTestWithBullet
#     def before_setup
#       Bullet.start_request
#       super if defined?(super)
#     end

#     def after_teardown
#       super if defined?(super)
#       Bullet.end_request
#     end
#   end

#   class ActiveSupport::TestCase
#     include MiniTestWithBullet
#   end
# end

require "rails/test_help"

class ActiveSupport::TestCase
  fixtures :all
end
