class Api::ThingsController < ApiController
  @fields = ['id', 'name']
  @create_fields = ['name']
  @update_fields = ['name']
end
