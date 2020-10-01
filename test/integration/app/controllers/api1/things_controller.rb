class Api1::ThingsController < Api1Controller
  include RESTFramework::ModelControllerMixin

  self.fields = [:id, :name, :shape, :price, :is_discounted, :created_at, :updated_at]
  self.action_fields = {
    create: [:name, :shape, :price, :is_discounted],
    update: [:name, :shape, :price, :is_discounted],
  }
  self.skip_actions = [:destroy]
end
