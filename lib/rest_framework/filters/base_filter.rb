class RESTFramework::Filters::BaseFilter
  def initialize(controller:)
    @controller = controller
  end

  def filter_data(data)
    raise NotImplementedError
  end

  # True when `v` is a query-parameter value safe to feed into `where`, string
  # operations, or `split` — i.e. a String or an Array of Strings. Guards against
  # nested-hash inputs like `?field[evil]=x`, which Rack parses into a Hash and
  # which AR cannot quote as a bind.
  def self._safe_query_value?(v)
    return true if v.is_a?(String)
    return v.all? { |el| el.is_a?(String) } if v.is_a?(Array)
    false
  end
end

# Alias for convenience.
RESTFramework::BaseFilter = RESTFramework::Filters::BaseFilter
