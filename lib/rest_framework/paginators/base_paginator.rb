class RESTFramework::Paginators::BasePaginator
  def initialize(data:, controller:, **kwargs)
    @data = data
    @controller = controller
  end

  # Get the page and return it so the caller can serialize it.
  def get_page
    raise NotImplementedError
  end

  # Wrap the serialized page with appropriate metadata.
  def get_paginated_response(serialized_page)
    raise NotImplementedError
  end
end

# Alias for convenience.
RESTFramework::BasePaginator = RESTFramework::Paginators::BasePaginator
