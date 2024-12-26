require_relative "model_controller_mixin"

# Mixin for creating records in bulk. This is unique compared to update/destroy because we overload
# the existing `create` action to support bulk creation.
module RESTFramework::Mixins::BulkCreateModelMixin
  # While bulk update/destroy are obvious because they create new router endpoints, bulk create
  # overloads the existing collection `POST` endpoint, so we add a special key to the OpenAPI
  # metadata to indicate bulk create is supported.
  def openapi_document
    return super.merge({"x-rrf-bulk-create": true})
  end

  def create
    if params[:_json].is_a?(Array)
      records = self.create_all!
      serialized_records = self.bulk_serialize(records)
      return render_api(serialized_records)
    end

    return super
  end

  # Perform the `create` call, and return the collection of (possibly) created records.
  def create_all!
    create_data = self.get_create_params(bulk_mode: true)[:_json]

    # Perform bulk create in a transaction.
    return ActiveRecord::Base.transaction do
      next self.get_create_from.create(create_data)
    end
  end
end

# Mixin for updating records in bulk.
module RESTFramework::Mixins::BulkUpdateModelMixin
  def update_all
    records = self.update_all!
    serialized_records = self.bulk_serialize(records)
    render_api(serialized_records)
  end

  # Perform the `update` call and return the collection of (possibly) updated records.
  def update_all!
    pk = self.class.get_model.primary_key
    update_data = if params[:_json].is_a?(Array)
      self.get_create_params(bulk_mode: :update)[:_json].index_by { |r| r[pk] }
    else
      create_params = self.get_create_params
      {create_params[pk] => create_params}
    end

    # Perform bulk update in a transaction.
    return ActiveRecord::Base.transaction do
      next self.get_recordset.update(update_data.keys, update_data.values)
    end
  end
end

# Mixin for destroying records in bulk.
module RESTFramework::Mixins::BulkDestroyModelMixin
  def destroy_all
    if params[:_json].is_a?(Array)
      records = self.destroy_all!
      serialized_records = self.bulk_serialize(records)
      return render_api(serialized_records)
    end

    render_api(
      {message: "Bulk destroy requires an array of primary keys as input."},
      status: 400,
    )
  end

  # Perform the `destroy!` call and return the destroyed (and frozen) record.
  def destroy_all!
    pk = self.class.get_model.primary_key
    destroy_data = self.request.request_parameters[:_json]

    # Perform bulk destroy in a transaction.
    return ActiveRecord::Base.transaction do
      next self.get_recordset.where(pk => destroy_data).destroy_all
    end
  end
end

# Mixin that includes all the CRUD bulk mixins.
module RESTFramework::Mixins::BulkModelControllerMixin
  include RESTFramework::Mixins::ModelControllerMixin

  include RESTFramework::Mixins::BulkCreateModelMixin
  include RESTFramework::Mixins::BulkUpdateModelMixin
  include RESTFramework::Mixins::BulkDestroyModelMixin

  def self.included(base)
    RESTFramework::Mixins::ModelControllerMixin.included(base)
  end
end

# Aliases for convenience.
RESTFramework::BulkCreateModelMixin = RESTFramework::Mixins::BulkCreateModelMixin
RESTFramework::BulkUpdateModelMixin = RESTFramework::Mixins::BulkUpdateModelMixin
RESTFramework::BulkDestroyModelMixin = RESTFramework::Mixins::BulkDestroyModelMixin
RESTFramework::BulkModelControllerMixin = RESTFramework::Mixins::BulkModelControllerMixin
