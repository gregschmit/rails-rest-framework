class Api1::ThingsController < Api1Controller
  include RESTFramework::ModelControllerMixin

  self.fields = [:name]
end
