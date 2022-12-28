module RESTFramework
  BUILTIN_ACTIONS = {
    index: :get,
    new: :get,
    create: :post,
  }.freeze
  BUILTIN_MEMBER_ACTIONS = {
    show: :get,
    edit: :get,
    update: [:put, :patch],
    destroy: :delete,
  }.freeze
  RRF_BUILTIN_ACTIONS = {
    options: :options,
  }.freeze
end

require_relative "rest_framework/controller_mixins"
require_relative "rest_framework/engine"
require_relative "rest_framework/errors"
require_relative "rest_framework/filters"
require_relative "rest_framework/generators"
require_relative "rest_framework/paginators"
require_relative "rest_framework/routers"
require_relative "rest_framework/serializers"
require_relative "rest_framework/utils"
require_relative "rest_framework/version"
