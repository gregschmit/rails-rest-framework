require_relative "models"

# Mixin for creating records in bulk. This is unique compared to update/destroy because we overload
# the existing `create` action to support bulk creation.
# :nocov:
module RESTFramework::BulkCreateModelMixin
  def create
    status, payload = self.create_all!
    return api_response(payload, status: status)
  end

  # Perform the `create` or `insert_all` call and return the created records with any errors. The
  # result should be of the form: `(status, payload)`, and `payload` should be of the form:
  # `[{success:, record: | errors:}]`, unless batch mode is enabled, in which case `payload` is
  # blank with a status of `202`.
  def create_all!
    if self.class.bulk_batch_mode
      insert_from = if self.get_recordset.respond_to?(:insert_all) && self.create_from_recordset
        # Create with any properties inherited from the recordset. We exclude any `select` clauses
        # in case model callbacks need to call `count` on this collection, which typically raises a
        # SQL `SyntaxError`.
        self.get_recordset.except(:select)
      else
        # Otherwise, perform a "bare" insert_all.
        self.class.get_model
      end

      insert_from
    end

    # Perform bulk creation, possibly in a transaction.
    self.class._rrf_bulk_transaction do
      if self.get_recordset.respond_to?(:insert_all) && self.create_from_recordset
        # Create with any properties inherited from the recordset. We exclude any `select` clauses
        # in case model callbacks need to call `count` on this collection, which typically raises a
        # SQL `SyntaxError`.
        return self.get_recordset.except(:select).create!(self.get_create_params)
      else
        # Otherwise, perform a "bare" insert_all.
        return self.class.get_model.insert_all(self.get_create_params)
      end
    end
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
# :nocov:
