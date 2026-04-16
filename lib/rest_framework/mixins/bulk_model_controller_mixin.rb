module RESTFramework::Mixins::BulkCreateModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(<<~TXT).squish
      BulkCreateModelMixin is deprecated; set the `bulk = true` class attribute instead.
    TXT

    base.bulk = true
  end
end

# Mixin for updating records in bulk.
module RESTFramework::Mixins::BulkUpdateModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(<<~TXT).squish
      BulkUpdateModelMixin is deprecated; set the `bulk = true`, and `excluded_actions` class
      attributes instead.
    TXT

    base.bulk = true
    base.excluded_actions = (base.excluded_actions - [ :update_all ]).freeze
  end
end

# Mixin for destroying records in bulk.
module RESTFramework::Mixins::BulkDestroyModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(<<~TXT).squish
      BulkDestroyModelMixin is deprecated; set the `bulk = true`, and `excluded_actions` class
      attributes instead.
    TXT

    base.bulk = true
    base.excluded_actions = (base.excluded_actions - [ :destroy_all ]).freeze
  end
end

# Mixin that includes all the CRUD bulk mixins.
module RESTFramework::Mixins::BulkModelControllerMixin
  def self.included(base)
    RESTFramework.deprecator.warn(<<~TXT).squish
      BulkModelControllerMixin is deprecated; use RESTFramework::Controller and set the `model` and
      `bulk = true` class attributes instead.
    TXT

    base.include(RESTFramework::Controller)
    base.model = RESTFramework::Utils.get_model(base)
    base.bulk = true
  end
end

# Aliases for convenience.
RESTFramework::BulkCreateModelMixin = RESTFramework::Mixins::BulkCreateModelMixin
RESTFramework::BulkUpdateModelMixin = RESTFramework::Mixins::BulkUpdateModelMixin
RESTFramework::BulkDestroyModelMixin = RESTFramework::Mixins::BulkDestroyModelMixin
RESTFramework::BulkModelControllerMixin = RESTFramework::Mixins::BulkModelControllerMixin
