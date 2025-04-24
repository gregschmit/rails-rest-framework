# A simple filtering backend that supports filtering a recordset based on query parameters.
class RESTFramework::Filters::QueryFilter < RESTFramework::Filters::BaseFilter
  # Wrapper to indicate a type of query that must be negated with `where.not(...)`.
  class Not
    attr_reader :q

    def initialize(q)
      @q = q
    end
  end

  PREDICATES = {
    true: true,
    false: false,
    null: nil,
    lt: ->(f, v) { {f => ...v} },
    # `gt` must negate `lte` because Rails doesn't support `>` with endless ranges.
    gt: ->(f, v) { Not.new({f => ..v}) },
    lte: ->(f, v) { {f => ..v} },
    gte: ->(f, v) { {f => v..} },
    not: ->(f, v) { Not.new({f => v}) },
    cont: ->(f, v) { ["#{f} LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(v)}%"] },
    in: ->(f, v) {
      if v.is_a?(Array)
        {f => v.map { |v| v == "null" ? nil : v }}
      elsif v.is_a?(String)
        {f => v.split(",").map { |v| v == "null" ? nil : v }}
      end
    },
  }.freeze
  PREDICATES_REGEX = /^(.*)_(#{PREDICATES.keys.join("|")})$/

  # Get a list of filter fields for the current action.
  def _get_fields
    # Always return a list of strings; `@controller.get_fields` already does this.
    return @controller.class.filter_fields&.map(&:to_s) || @controller.get_fields
  end

  # Helper to find a variation of a field using a predicate. For example, there could be a field
  # called `age`, and if `age_lt` it passed, we should return `["age", "lt"]`. Otherwise, if
  # something like `age` is passed, then we should return `["age", nil]`.
  def parse_predicate(field)
    if match = PREDICATES_REGEX.match(field)
      field = match[1]
      predicate = match[2]
    end

    return field, predicate
  end

  # Filter params for keys allowed by the current action's filter_fields/fields config and return a
  # query config in the form of: `[base_query, pred_queries, includes]`.
  def _get_query_config
    fields = self._get_fields
    includes = []

    # Predicate queries must be added to a separate list because multiple predicates can be used.
    # E.g., `age_lt=10&age_gte=5` would transform to `[{age: ...10}, {age: 5..}]` to avoid conflict
    # on the `age` key.
    pred_queries = []

    base_query = @controller.request.query_parameters.map { |field, v|
      # First, if field is a simple filterable field, return early.
      if field.in?(fields)
        next [field, v]
      end

      # First, try to parse a simple predicate and check if it is filterable.
      pred_field, predicate = self.parse_predicate(field)
      if predicate && pred_field.in?(fields)
        field = pred_field
      else
        # Last, try to parse a sub-field or sub-field w/predicate.
        root_field, sub_field = field.split(".", 2)
        _, pred_sub_field = pred_field.split(".", 2) if predicate

        # Check if sub-field or sub-field w/predicate is filterable.
        if sub_field
          next nil unless root_field.in?(fields)

          sub_fields = @controller.class.field_configuration[root_field][:sub_fields] || []
          if sub_field.in?(sub_fields)
            includes << root_field.to_sym
            next [field, v]
          elsif pred_sub_field && pred_sub_field.in?(sub_fields)
            includes << root_field.to_sym
            field = pred_field
          else
            next nil
          end
        else
          next nil
        end
      end

      # If we get here, we must have a predicate, either from a field or a sub-field. Transform the
      # value into a query that can be used in the ActiveRecord `where` API.
      cfg = PREDICATES[predicate.to_sym]
      if cfg.is_a?(Proc)
        pred_queries << cfg.call(field, v)
      else
        pred_queries << {field => cfg}
      end

      next nil
    }.compact.to_h.symbolize_keys

    puts "GNS: #{base_query.inspect} #{pred_queries.inspect} #{includes.inspect}"
    return base_query, pred_queries, includes
  end

  # Filter data according to the request query parameters.
  def filter_data(data)
    base_query, pred_queries, includes = self._get_query_config

    if base_query.any? || pred_queries.any?
      if includes.any?
        data = data.includes(*includes)
      end

      data = data.where(**base_query) if base_query.any?

      pred_queries.each do |q|
        if q.is_a?(Not)
          data = data.where.not(q.q)
        else
          data = data.where(q)
        end
      end
    end

    return data
  end
end

# Alias for convenience.
RESTFramework::QueryFilter = RESTFramework::Filters::QueryFilter
