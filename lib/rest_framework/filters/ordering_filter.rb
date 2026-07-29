# A filter backend which handles ordering of the recordset.
class RESTFramework::Filters::OrderingFilter < RESTFramework::Filters::BaseFilter
  def _get_fields
    @controller.class.ordering_fields&.map(&:to_s) || @controller.get_fields
  end

  # Convert the ordering param into an `[ordering, references]` pair: the ordering config for
  # `order`/`reorder`, and the association names that must be joined for it to resolve.
  def _get_ordering
    return nil unless param = @controller.class.ordering_query_param.presence

    # Ensure ordering_fields are strings since the split param will be strings.
    fields = self._get_fields
    order_string = @controller.params[param]

    # Reject nested-hash inputs like `?ordering[evil]=x` (Rack parses these into
    # a Hash, which can't be split into ordering tokens).
    return nil unless self.class._safe_query_value?(order_string)
    return nil unless order_string.present?

    ordering = {}.with_indifferent_access
    references = []

    order_string = order_string.join(",") if order_string.is_a?(Array)
    order_string.split(",").map(&:strip).each do |field|
      if field[0] == "-"
        column = field[1..-1]
        direction = :desc
      else
        column = field
        direction = :asc
      end

      # A plain, directly-allowlisted field.
      if column.in?(fields)
        ordering[column] = direction
        next
      end

      # A dotted `association.sub_field` token. The root must be an allowlisted association field,
      # and the sub-field must be one of that association's allowlisted sub_fields. Otherwise a
      # client could order by (and infer, via an ordering oracle) a column that is never serialized.
      root, sub = column.split(".", 2)
      next unless sub && root.in?(fields)

      cfg = @controller.class.field_configuration[root]
      next unless cfg && sub.in?(cfg[:sub_fields] || [])

      ordering[column] = direction
      references << root.to_sym
    end

    return nil if ordering.empty?

    [ ordering, references ]
  end

  # Order data according to the request query parameters.
  def filter_data(data)
    ordering, references = self._get_ordering
    return data unless ordering

    # Join any referenced associations so dotted ordering keys resolve instead of raising.
    data = data.includes(*references).references(*references) if references.present?

    reorder = !@controller.class.ordering_no_reorder
    data.send(reorder ? :reorder : :order, ordering)
  end
end

# Alias for convenience.
RESTFramework::OrderingFilter = RESTFramework::Filters::OrderingFilter
