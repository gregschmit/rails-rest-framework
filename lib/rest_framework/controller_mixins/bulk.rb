require_relative "models"

# Mixin for creating records in bulk. This is unique compared to update/destroy because we overload
# the existing `create` action to support bulk creation.
# :nocov:
module RESTFramework::BulkCreateModelMixin
  # While bulk update/destroy are obvious because they create new router endpoints, bulk create
  # overloads the existing collection `POST` endpoint, so we add a special key to the options
  # metadata to indicate bulk create is supported.
  def get_options_metadata
    return super.merge({bulk_create: true})
  end

  def create
    if params[:_json].is_a?(Array)
      records = self.create_all!

      # Serialize
      # This is kinda slow, so perhaps we should eventually integrate `errors` serialization into
      # the serializer directly. This would fail for active model serializers, but maybe we don't
      # care?
      serializer_class = self.get_serializer_class
      records.map! do |record|
        serializer_class.new(record, controller: self).serialize.merge!(
          {errors: record.errors.presence}.compact,
        )
      end

      return api_response(records)
    end

    return super
  end

  # Perform the `create` or `insert_all` call, and return the collection of records, which in the
  # case of `insert_all` (batch mode) will be empty because the records are not instantiated.
  def create_all!
    if self.class.bulk_batch_mode
      self.get_create_from.insert_all!(self.get_create_params(json_array: true)[:_json])
      return []
    end

    # Perform bulk creation in a transaction.
    records = ActiveRecord::Base.transaction do
      next self.get_create_from.create(self.get_create_params(json_array: true)[:_json])
    end
    return records
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
