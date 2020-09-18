class Api1::ThingsController < Api1Controller
  @fields = ['id', 'name']
  @create_fields = ['name']
  @update_fields = ['name']
  @skip_actions = [:destroy]
end
