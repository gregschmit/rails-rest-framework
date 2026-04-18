class Api::Test::TestaController < ApplicationController
  include RESTFramework::Controller
  self.model = Testum
end
