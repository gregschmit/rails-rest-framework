class Api2::ThingsController < Api2Controller
  include RESTFramework::ModelControllerMixin

  @fields = ['id', 'name']
  @create_fields = ['name']
  @update_fields = ['name']
end
