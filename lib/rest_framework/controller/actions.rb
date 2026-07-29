module RESTFramework::Controller
  # Value object describing a routed action (builtin or user-declared).
  ActionSpec = Struct.new(
    :name, :type, :methods, :path, :metadata, :builtin, :kwargs, keyword_init: true
  )

  # Builtin actions keyed by name, each gated by a `condition` so only applicable ones surface in
  # `actions` / `member_actions`. They route at the base path (`""`) of their scope.
  RRF_BUILTIN_COLLECTION_ACTIONS = {
    index: { methods: [ :get ], condition: ->(c) { !c.singular }, kwargs: { as: "" } },
    create: { methods: [ :post ], condition: ->(c) { c.model } },
    update_all: {
      methods: [ :put, :patch ],
      condition: ->(c) { c.model && c.bulk && !c.singular },
      kwargs: { anchor: true },
    },
    destroy_all: {
      methods: [ :delete ],
      condition: ->(c) { c.model && c.bulk && !c.singular },
      kwargs: { anchor: true },
    },
    options: { methods: [ :options ], condition: ->(_c) { true }, kwargs: { anchor: true } },
  }.freeze
  RRF_BUILTIN_MEMBER_ACTIONS = {
    show: { methods: [ :get ], condition: ->(c) { c.model } },
    update: { methods: [ :put, :patch ], condition: ->(c) { c.model } },
    destroy: { methods: [ :delete ], condition: ->(c) { c.model } },
  }.freeze

  module ClassMethods
    # Per-class action deltas (internal). Public because composition reads them off ancestors.
    def _rrf_action_adds(type)
      if type == :member
        @_rrf_member_action_adds ||= {}
      else
        @_rrf_collection_action_adds ||= {}
      end
    end

    def _rrf_action_removes(type)
      if type == :member
        @_rrf_member_action_removes ||= {}
      else
        @_rrf_collection_action_removes ||= {}
      end
    end

    # Route an action, choosing the collection/member scope. Pass `type:` on a plural model
    # controller, where the scopes differ; elsewhere the scope is implied — a singular controller's
    # sole resource is a member (so `delegate` targets the record), a modelless one has only a
    # collection — and `type:` warns as unnecessary (unless the action is delegated).
    def add_action(name, methods, type: nil, **opts)
      singular_model = self.model && self.singular

      if self.model && !self.singular
        _rrf_warn_action(name, methods, type, :ambiguous) if type.nil?
      elsif singular_model && type && !opts[:metadata]&.[](:delegate)
        _rrf_warn_action(name, methods, type, :redundant)
      end

      _rrf_add_action(type || (singular_model ? :member : :collection), name, methods, **opts)
    end

    # Remove an action from routing (including builtins). With no `type:`, both scopes are removed —
    # keeping removal simple, and letting `propagate:` carry it to model descendants where member
    # scope matters. Pass `type:` to target a single scope.
    def remove_action(name, type: nil, propagate: false)
      if type
        _rrf_remove_action(type, name, propagate: propagate)
      else
        _rrf_remove_action(:collection, name, propagate: propagate)
        _rrf_remove_action(:member, name, propagate: propagate)
      end
    end

    def remove_actions(*names, type: nil, propagate: false)
      names.each { |name| remove_action(name, type: type, propagate: propagate) }
    end

    # Source of truth: the effective collection / member actions (builtins + declared, composed
    # across the inheritance chain), as an ordered `Hash{Symbol => ActionSpec}`.
    def actions
      _rrf_compose_actions(:collection)
    end

    def member_actions
      _rrf_compose_actions(:member)
    end

    private

    def _rrf_add_action(type, name, methods, path: nil, metadata: nil, propagate: false, **kwargs)
      name = name.to_sym
      spec = ActionSpec.new(
        name: name,
        type: type,
        methods: Array(methods).map(&:to_sym),
        path: (path || name).to_s,
        metadata: metadata,
        builtin: false,
        kwargs: kwargs,
      )
      _rrf_action_removes(type).delete(name)
      _rrf_action_adds(type)[name] = { spec: spec, propagate: _rrf_normalize_propagate(propagate) }
    end

    def _rrf_remove_action(type, name, propagate: false)
      name = name.to_sym
      _rrf_action_adds(type).delete(name)
      _rrf_action_removes(type)[name] = { propagate: _rrf_normalize_propagate(propagate) }
    end

    # Normalize `propagate:` to `false` (local), `true` (self + descendants), or `:exclude_self`
    # (descendants only). Non-standard values warn: `nil` becomes `false`, anything else truthy
    # becomes `true`.
    def _rrf_normalize_propagate(value)
      case value
      when false
        false
      when true, :exclude_self
        value
      when nil
        Rails.logger.warn("RRF: `propagate: nil` is nonstandard; treating as `false`.")
        false
      else
        Rails.logger.warn("RRF: invalid `propagate:` value #{value.inspect}; treating as `true`.")
        true
      end
    end

    # Whether an entry with the given `propagate`, declared on some class, reaches the controller
    # we're composing for. `is_self` is true when that class is the controller itself.
    def _rrf_reaches?(propagate, is_self)
      case propagate
      when :exclude_self
        !is_self
      when true
        true
      else # false
        is_self
      end
    end

    def _rrf_builtins(type)
      type == :member ? RRF_BUILTIN_MEMBER_ACTIONS : RRF_BUILTIN_COLLECTION_ACTIONS
    end

    def _rrf_compose_actions(type)
      effective = {}

      # 1. Seed with the builtins whose condition holds for this controller.
      _rrf_builtins(type).each do |name, cfg|
        next unless cfg[:condition].call(self)

        effective[name] = ActionSpec.new(
          name: name,
          type: type,
          methods: cfg[:methods],
          path: "",
          metadata: nil,
          builtin: true,
          kwargs: cfg[:kwargs] || {},
        )
      end

      # 2. Walk RRF ancestors from farthest to nearest (ending at self), applying each class's
      #    removes then adds that reach us. Removes-before-adds lets a subclass re-add something an
      #    ancestor removed; later (nearer) classes win.
      _rrf_action_chain.each do |klass|
        is_self = klass.equal?(self)

        klass._rrf_action_removes(type).each do |name, remove|
          effective.delete(name) if _rrf_reaches?(remove[:propagate], is_self)
        end

        klass._rrf_action_adds(type).each do |name, add|
          effective[name] = add[:spec] if _rrf_reaches?(add[:propagate], is_self)
        end
      end

      effective
    end

    def _rrf_action_chain
      self.ancestors.select { |a| a.is_a?(Class) && a.respond_to?(:_rrf_action_adds) }.reverse
    end

    # Build the `type:` warning for `add_action`, echoing the call so its source is easy to find.
    def _rrf_warn_action(name, methods, type, reason)
      type_arg = type ? ", type: #{type.inspect}" : ""
      sig = "add_action(#{name.inspect}, #{methods.inspect}#{type_arg})"

      detail =
        if reason == :ambiguous
          "needs an explicit `type:` (`:collection` or `:member`); collection and member route " \
            "differently on a plural model controller"
        else
          "has an unnecessary `type:`; member and collection route the same path on a singular " \
            "model controller"
        end

      Rails.logger.warn("RRF: `#{sig}` #{detail}.")
    end
  end

  # Delegated actions (`metadata: { delegate: true }`) dispatch through `rrf_delegate` while keeping
  # their declared name for routing and introspection. The route marks itself delegated with the
  # `rrf_delegate_scope` path parameter, so dispatch is route-based and never collides with a
  # same-named method.
  def method_for_action(action_name)
    request&.path_parameters&.key?(:rrf_delegate_scope) ? "rrf_delegate" : super
  end

  # Dispatch a delegated action to the model class (collection) or the record (member). Its declared
  # name is `action_name`; its scope comes from the route.
  def rrf_delegate
    target = self.action_name.to_sym
    member = request.path_parameters[:rrf_delegate_scope].to_s == "member"
    receiver = member ? self.get_record : self.class.model

    if receiver.method(target).parameters.last&.first == :keyrest
      render_api(receiver.send(target, **request.query_parameters.symbolize_keys))
    else
      render_api(receiver.send(target))
    end
  end
end
