require_relative "models"

# Mixin for creating records in bulk. This is unique compared to update/destroy because we overload
# the existing `create` action to support bulk creation.
module RESTFramework::BulkCreateModelMixin
  def create
    raise NotImplementedError, "TODO"
  end

  # Perform the `create!` call and return the created record.
  def create_all!
    raise NotImplementedError, "TODO"
  end
end

# Mixin for updating records in bulk.
module RESTFramework::BulkUpdateModelMixin
  def update_all
    raise NotImplementedError, "TODO"
  end

  # Perform the `update!` call and return the updated record.
  def update_all!
    raise NotImplementedError, "TODO"
  end
end

# Mixin for destroying records in bulk.
module RESTFramework::BulkDestroyModelMixin
  def destroy_all
    raise NotImplementedError, "TODO"
  end

  # Perform the `destroy!` call and return the destroyed (and frozen) record.
  def destroy_all!
    raise NotImplementedError, "TODO"
  end
end

# Mixin that includes all the CRUD bulk mixins.
module RESTFramework::BulkModelControllerMixin
  include RESTFramework::ModelControllerMixin

  include RESTFramework::BulkCreateModelMixin
  include RESTFramework::BulkUpdateModelMixin
  include RESTFramework::BulkDestroyModelMixin

  def self.included(base)
    RESTFramework::ModelControllerMixin.included(base)
  end
end
