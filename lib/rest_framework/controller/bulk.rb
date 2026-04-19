module RESTFramework::Controller
  RRF_DEFAULT_BULK_MAX_SIZE = 1000
  RRF_DEFAULT_BULK_MAX_RAW_SIZE = 10000

  def _bulk_max_size
    @_bulk_max_size ||= self.class.bulk_max_size || RRF_DEFAULT_BULK_MAX_SIZE
  end

  def _bulk_max_raw_size
    @_bulk_max_raw_size ||= self.class.bulk_max_raw_size || RRF_DEFAULT_BULK_MAX_RAW_SIZE
  end

  def _bulk_serialize(records)
    # This is kinda slow, so perhaps we should eventually integrate `errors` serialization into
    # the serializer directly. This would fail for active model serializers, but maybe we don't
    # care?
    s = RESTFramework::Utils.wrap_ams(self.get_serializer_class)
    records.map do |record|
      s.new(record, controller: self).serialize.merge!({ errors: record.errors.presence }.compact)
    end
  end

  def _bulk_mode
    return @_bulk_mode if defined?(@_bulk_mode)

    # If mode override is allowed, check the query param.
    if self.class.bulk_allow_mode_override && (qp = self.class.bulk_mode_query_param)
      if (requested = request.query_parameters[qp].presence)
        requested = requested.to_sym
        unless requested.in?([ :default, :raw ])
          raise RESTFramework::InvalidBulkParametersError.new(
            "Invalid bulk mode: #{requested}. Must be `default` or `raw`.",
          )
        end
        return @_bulk_mode = requested
      end
    end

    # Normalize: `true` and `:default` both mean per-record processing.
    @_bulk_mode = self.class.bulk == :raw ? :raw : :default
  end

  # Resolve whether partial fulfillment is enabled for this request.
  def _bulk_partial
    return @_bulk_partial if defined?(@_bulk_partial)

    # Check the query param first if configured.
    if (qp = self.class.bulk_partial_query_param)
      if (requested = request.query_parameters[qp].presence)
        return @_bulk_partial = ActiveModel::Type::Boolean.new.cast(requested)
      end
    end

    @_bulk_partial = self.class.bulk_partial
  end

  # Validate and extract bulk object data from request parameters.
  def _bulk_object_data(bulk_action, bulk_mode)
    data = self.get_body_params(bulk_action: bulk_action)[:_json]

    unless data&.is_a?(Array) && data.all? { |r| r.is_a?(ActionController::Parameters) }
      raise RESTFramework::InvalidBulkParametersError.new("Expected an array of objects.")
    end

    # Enforce size limits.
    max = bulk_mode == :raw ? self._bulk_max_raw_size : self._bulk_max_size
    if max && data.length > max
      raise RESTFramework::InvalidBulkParametersError.new(
        "Too many records (#{data.length}) for #{bulk_mode} mode; maximum is #{max}.",
      )
    end

    data
  end

  # Validate and extract bulk primary key data from request parameters.
  def _bulk_pk_data
    data = self.get_destroy_params(bulk_action: :destroy)[:_json]

    unless data&.is_a?(Array) && data.all? { |r| r.is_a?(String) || r.is_a?(Numeric) }
      raise RESTFramework::InvalidBulkParametersError.new("Expected an array of primary keys.")
    end

    # Enforce size limits.
    max = self._bulk_mode == :raw ? self._bulk_max_raw_size : self._bulk_max_size
    if max && data.length > max
      raise RESTFramework::InvalidBulkParametersError.new(
        "Too many records (#{data.length}) for #{self._bulk_mode} mode; maximum is #{max}.",
      )
    end

    data
  end

  def create_all
    if self._bulk_mode == :raw
      result = self.create_all_raw!
      return render(api: { message: "Bulk create successful.", result: result })
    end

    records = self.create_all_default!
    render(
      api: { message: "Bulk create successful.", records: self._bulk_serialize(records) },
      status: :created,
    )
  end

  def create_all_raw!
    pk = self.class.model.primary_key
    data = self._bulk_object_data(:create, :raw)

    unless first_keys = data.first&.keys&.sort
      raise RESTFramework::InvalidBulkParametersError.new("Expected objects with attrs.")
    end
    unless data.all? { |r| r.keys.sort == first_keys }
      raise RESTFramework::InvalidBulkParametersError.new("All objects must have the same attrs.")
    end

    self.create_from.insert_all(data, unique_by: pk)
  end

  def create_all_default!
    data = self._bulk_object_data(:create, :default)
    collection = self.create_from

    if self._bulk_partial
      # Partial: save each record individually, return all (some may have errors).
      data.map { |attrs| collection.create(attrs) }
    else
      # Transactional: validate all first, then save in a transaction or raise.
      records = data.map { |attrs| collection.new(attrs) }
      failed = records.reject(&:valid?)

      if failed.any?
        raise RESTFramework::BulkRecordErrorsError.new(records)
      end

      self.class.model.transaction do
        records.each(&:save!)
      end

      records
    end
  end

  def update_all
    if self._bulk_mode == :raw
      result = self.update_all_raw!
      return render(api: { message: "Bulk update successful.", result: result })
    end

    records = self.update_all_default!
    render(api: { message: "Bulk update successful.", records: self._bulk_serialize(records) })
  end

  def update_all_raw!
    pk = self.class.model.primary_key
    data = self._bulk_object_data(:update, :raw)

    data_ids = data.map { |r| r[pk] }.uniq
    if data_ids.include?(nil)
      raise RESTFramework::InvalidBulkParametersError.new(
        "Bulk update requires the primary key (#{pk}) for all records.",
      )
    end
    found_ids = self.get_recordset.where(pk => data_ids).pluck(pk)
    if found_ids.length != data_ids.length
      missing = data_ids - found_ids
      raise RESTFramework::InvalidBulkParametersError.new(
        "Records not found with #{pk}: #{missing.join(', ')}.",
      )
    end

    unless first_keys = data.first&.keys&.sort
      raise RESTFramework::InvalidBulkParametersError.new("Expected objects with attrs.")
    end
    unless data.all? { |r| r.keys.sort == first_keys }
      raise RESTFramework::InvalidBulkParametersError.new("All objects must have the same attrs.")
    end

    self.get_recordset.upsert_all(data, unique_by: pk)
  end

  def update_all_default!
    pk = self.class.model.primary_key
    data = self._bulk_object_data(:update, :default)

    data_ids = data.map { |r| r[pk] }.uniq
    if data_ids.include?(nil)
      raise RESTFramework::InvalidBulkParametersError.new(
        "Bulk update requires the primary key (#{pk}) for all records.",
      )
    end
    existing = self.get_recordset.where(pk => data_ids).index_by { |r| r.send(pk) }
    if existing.length != data_ids.length
      missing = data_ids - existing.keys
      raise RESTFramework::InvalidBulkParametersError.new(
        "Records not found with #{pk}: #{missing.join(', ')}.",
      )
    end

    # Assign attributes to each record.
    records = data.map { |attrs|
      record = existing[attrs[pk]]
      record.assign_attributes(attrs.except(pk))
      record
    }

    if self._bulk_partial
      # Partial: save each record individually.
      records.each(&:save)
      records
    else
      # Transactional: validate all first, then save in a transaction or raise.
      failed = records.reject(&:valid?)

      if failed.any?
        raise RESTFramework::BulkRecordErrorsError.new(records)
      end

      self.class.model.transaction do
        records.each(&:save!)
      end

      records
    end
  end

  def destroy_all
    if self._bulk_mode == :raw
      deleted = self.destroy_all_raw!
      return render(api: { message: "Bulk destroy successful.", result: deleted })
    end

    records = self.destroy_all_default!
    render(api: { message: "Bulk destroy successful.", records: self._bulk_serialize(records) })
  end

  def destroy_all_raw!
    data = self._bulk_pk_data
    pk = self.class.model.primary_key
    self.get_recordset.where(pk => data).delete_all
  end

  def destroy_all_default!
    data = self._bulk_pk_data
    pk = self.class.model.primary_key
    records = self.get_recordset.where(pk => data).to_a

    # In transactional mode, verify all requested records exist.
    if !self._bulk_partial && records.length != data.uniq.length
      found_ids = records.map { |r| r.send(pk) }
      missing = data.uniq - found_ids
      raise RESTFramework::InvalidBulkParametersError.new(
        "Bulk destroy requires all records to exist. Missing #{pk}: #{missing.join(', ')}.",
      )
    end

    if self._bulk_partial
      # Partial: destroy each record individually.
      records.each(&:destroy)
      records
    else
      # Transactional: destroy all in a transaction, roll back on failure.
      self.class.model.transaction do
        records.each(&:destroy!)
      end

      records
    end
  end
end
