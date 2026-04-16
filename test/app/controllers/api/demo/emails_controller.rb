class Api::Demo::EmailsController < Api::DemoController
  self.model = Email
  self.bulk = true
end
