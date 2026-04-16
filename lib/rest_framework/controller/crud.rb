module RESTFramework::Controller
  def create
    # Bulk create: if `bulk` is enabled and the request body is an array, delegate to `create_all!`.
    if self.class.bulk && params[:_json].is_a?(Array)
      records = self.create_all!
      return render(api: self.bulk_serialize(records))
    end

    render(api: self.create!, status: :created)
  end

  # Perform the `create!` call and return the created record.
  def create!
    self.create_from.create!(self.get_create_params)
  end

  def index
    render(api: self.get_index_records)
  end

  # Get records with both filtering and pagination applied.
  def get_index_records
    records = self.get_records

    # Handle pagination, if enabled.
    if paginator_class = self.class.paginator_class
      # Paginate if there is a `max_page_size`, or if there is no `page_size_query_param`, or if the
      # page size is not set to "0".
      max_page_size = self.class.max_page_size
      page_size_query_param = self.class.page_size_query_param
      if max_page_size || !page_size_query_param || params[page_size_query_param] != "0"
        paginator = paginator_class.new(data: records, controller: self)
        page = paginator.get_page
        serialized_page = self.serialize(page)
        return paginator.get_paginated_response(serialized_page)
      end
    end

    records
  end

  def show
    render(api: self.get_record)
  end

  def update
    render(api: self.update!)
  end

  # Perform the `update!` call and return the updated record.
  def update!
    record = self.get_record
    record.update!(self.get_update_params)
    record
  end

  def destroy
    self.destroy!
    render(api: "")
  end

  # Perform the `destroy!` call and return the destroyed (and frozen) record.
  def destroy!
    self.get_record.destroy!
  end
end
