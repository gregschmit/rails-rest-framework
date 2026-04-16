module RESTFramework::Controller
  # Serialize the records, but also include any errors that might exist. This is used for bulk
  # actions, however we include it here so the helper is available everywhere.
  def bulk_serialize(records)
    # This is kinda slow, so perhaps we should eventually integrate `errors` serialization into
    # the serializer directly. This would fail for active model serializers, but maybe we don't
    # care?
    s = RESTFramework::Utils.wrap_ams(self.get_serializer_class)
    records.map do |record|
      s.new(record, controller: self).serialize.merge!({ errors: record.errors.presence }.compact)
    end
  end

  # Perform the `create` call, and return the collection of (possibly) created records.
  def create_all!
    create_data = self.get_create_params(bulk_mode: true)[:_json]

    # Perform bulk create in a transaction.
    ActiveRecord::Base.transaction { self.create_from.create(create_data) }
  end

  def update_all
    records = self.update_all!
    serialized_records = self.bulk_serialize(records)
    render(api: serialized_records)
  end

  # Perform the `update` call and return the collection of (possibly) updated records.
  def update_all!
    pk = self.class.model.primary_key
    data = if params[:_json].is_a?(Array)
      self.get_create_params(bulk_mode: :update)[:_json].index_by { |r| r[pk] }
    else
      create_params = self.get_create_params
      { create_params[pk] => create_params }
    end

    # Perform bulk update in a transaction.
    ActiveRecord::Base.transaction { self.get_recordset.update(data.keys, data.values) }
  end

  def destroy_all
    if params[:_json].is_a?(Array)
      records = self.destroy_all!
      serialized_records = self.bulk_serialize(records)
      return render(api: serialized_records)
    end

    render(
      api: { message: "Bulk destroy requires an array of primary keys as input." }, status: 400,
    )
  end

  # Perform the `destroy!` call and return the destroyed (and frozen) record.
  def destroy_all!
    pk = self.class.model.primary_key
    destroy_data = self.request.request_parameters[:_json]

    # Perform bulk destroy in a transaction.
    ActiveRecord::Base.transaction { self.get_recordset.where(pk => destroy_data).destroy_all }
  end
end
