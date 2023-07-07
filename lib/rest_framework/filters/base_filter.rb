class RESTFramework::Filters::BaseFilter
  def initialize(controller:)
    @controller = controller
  end

  def get_filtered_data(data)
    raise NotImplementedError
  end
end

# Alias for convenience.
RESTFramework::BaseFilter = RESTFramework::Filters::BaseFilter
