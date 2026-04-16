class Api::Demo::PhoneNumbersController < Api::DemoController
  self.model = PhoneNumber
  self.bulk = true
end
