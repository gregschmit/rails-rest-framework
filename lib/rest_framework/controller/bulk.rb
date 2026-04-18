module RESTFramework::Controller
  # Serialize the records, but also include any errors that might exist.
  def bulk_serialize(records)
    # This is kinda slow, so perhaps we should eventually integrate `errors` serialization into
    # the serializer directly. This would fail for active model serializers, but maybe we don't
    # care?
    s = RESTFramework::Utils.wrap_ams(self.get_serializer_class)
    records.map do |record|
      s.new(record, controller: self).serialize.merge!({ errors: record.errors.presence }.compact)
    end
  end

  def create_all!
    pk = self.class.model.primary_key
    data = self.get_create_params(bulk_mode: true)[:_json]

    unless data&.is_a?(Array) && data.all? { |r| r.is_a?(ActionController::Parameters) }
      raise RESTFramework::InvalidBulkParametersError.new("Expected an array of objects.")
    end

    unless first_keys = data.first&.keys&.sort
      raise RESTFramework::InvalidBulkParametersError.new("Expected objects with attrs.")
    end
    unless data.all? { |r| r.keys.sort == first_keys }
      raise RESTFramework::InvalidBulkParametersError.new("All objects must have the same attrs.")
    end

    self.create_from.insert_all(data, unique_by: pk)
  end

  def update_all
    result = self.update_all!
    render(api: { result: result })
  end

  def update_all!
    pk = self.class.model.primary_key
    data = self.get_update_params(bulk_mode: :update)[:_json]

    unless data&.is_a?(Array) && data.all? { |r| r.is_a?(ActionController::Parameters) }
      raise RESTFramework::InvalidBulkParametersError.new("Expected an array of objects.")
    end

    data_ids = data.map { |r| r[pk] }.uniq
    if self.get_recordset.where(pk => data_ids).count != data_ids.length
      raise RESTFramework::InvalidBulkParametersError.new("Some objects not found.")
    end

    unless first_keys = data.first&.keys&.sort
      raise RESTFramework::InvalidBulkParametersError.new("Expected objects with attrs.")
    end
    unless data.all? { |r| r.keys.sort == first_keys }
      raise RESTFramework::InvalidBulkParametersError.new("All objects must have the same attrs.")
    end

    self.get_recordset.upsert_all(data, unique_by: pk)
  end

  def destroy_all
    deleted = self.destroy_all!
    render(api: { result: deleted })
  end

  def destroy_all!
    pk = self.class.model.primary_key
    data = self.get_destroy_params(bulk_mode: :destroy)[:_json]

    unless data&.is_a?(Array) && data.all? { |r| r.is_a?(String) || r.is_a?(Numeric) }
      raise RESTFramework::InvalidBulkParametersError.new("Expected an array of primary keys.")
    end

    self.get_recordset.where(pk => data).delete_all
  end
end
