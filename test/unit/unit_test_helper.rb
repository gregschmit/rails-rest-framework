$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rails"
[
  'active_record/railtie',
  #'active_storage/engine',
  'action_controller/railtie',
  'action_view/railtie',
  #'action_mailer/railtie',
  'active_job/railtie',
  #'action_cable/engine',
  #'action_mailbox/engine',
  #'action_text/engine',
  'rails/test_unit/railtie',
  'sprockets/railtie',
].each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

require "rest_framework"

require "minitest/autorun"
require "minitest/pride"
