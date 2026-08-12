class RESTFramework::Filters::BaseFilter
  def initialize(controller:)
    @controller = controller
  end

  def filter_data(data)
    raise NotImplementedError
  end

  # The controller's polymorphic `<assoc>.id`/`<assoc>.type` → backing-column map, gated by a custom
  # field allowlist when the subclass defines one (`filter_fields`/`ordering_fields`). This keeps a
  # restricted allowlist restrictive: a polymorphic path is honored only if it is also listed there.
  def _polymorphic_columns(custom_fields)
    map = @controller.readable_polymorphic_columns
    return map unless custom_fields

    map.slice(*custom_fields.map(&:to_s))
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
