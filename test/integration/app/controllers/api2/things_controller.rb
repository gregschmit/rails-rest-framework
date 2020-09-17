class Api2::ThingsController < Api2Controller
  include RESTFramework::ModelControllerMixin

  @fields = %w(id name)
  @create_fields = @update_fields = %w(name)
end
