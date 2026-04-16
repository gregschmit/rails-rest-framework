module RESTFramework::Mixins::BaseModelControllerMixin
  def self.included(base)
    RESTFramework.deprecator.warn(<<~TXT).squish
      BaseModelControllerMixin is deprecated; use RESTFramework::Controller and set the `model` and
      `excluded_actions` class attributes instead.
    TXT

    base.include(RESTFramework::Controller)
    base.model = RESTFramework::Utils.get_model(base)
    base.excluded_actions = [
      :index, :show, :create, :update, :destroy, :update_all, :destroy_all
    ].freeze
  end
end

module RESTFramework::Mixins::ListModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(
      "ListModelMixin is deprecated; set the `excluded_actions` class attribute instead.",
    )

    if base.excluded_actions
      base.excluded_actions = (base.excluded_actions - [ :index ]).freeze
    end
  end
end

module RESTFramework::Mixins::ShowModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(
      "ShowModelMixin is deprecated; set the `excluded_actions` class attribute instead.",
    )

    if base.excluded_actions
      base.excluded_actions = (base.excluded_actions - [ :show ]).freeze
    end
  end
end

module RESTFramework::Mixins::CreateModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(
      "CreateModelMixin is deprecated; set the `excluded_actions` class attribute instead.",
    )

    if base.excluded_actions
      base.excluded_actions = (base.excluded_actions - [ :create ]).freeze
    end
  end
end

module RESTFramework::Mixins::UpdateModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(
      "UpdateModelMixin is deprecated; set the `excluded_actions` class attribute instead.",
    )

    if base.excluded_actions
      base.excluded_actions = (base.excluded_actions - [ :update ]).freeze
    end
  end
end

module RESTFramework::Mixins::DestroyModelMixin
  def self.included(base)
    RESTFramework.deprecator.warn(
      "DestroyModelMixin is deprecated; set the `excluded_actions` class attribute instead.",
    )

    if base.excluded_actions
      base.excluded_actions = (base.excluded_actions - [ :destroy ]).freeze
    end
  end
end

module RESTFramework::Mixins::ReadOnlyModelControllerMixin
  def self.included(base)
    RESTFramework.deprecator.warn(<<~TXT).squish
      ReadOnlyModelControllerMixin is deprecated; use RESTFramework::Controller and set the `model`
      and `excluded_actions` class attributes instead.
    TXT

    base.include(RESTFramework::Controller)
    base.model = RESTFramework::Utils.get_model(base)
    base.excluded_actions = [ :create, :update, :destroy, :update_all, :destroy_all ].freeze
  end
end

module RESTFramework::Mixins::ModelControllerMixin
  def self.included(base)
    RESTFramework.deprecator.warn(<<~TXT).squish
      ModelControllerMixin is deprecated; use RESTFramework::Controller and set the `model` class
      attribute instead.
    TXT

    base.include(RESTFramework::Controller)
    base.model = RESTFramework::Utils.get_model(base)
    base.excluded_actions = nil
  end
end

# Aliases for convenience.
RESTFramework::BaseModelControllerMixin = RESTFramework::Mixins::BaseModelControllerMixin
RESTFramework::ListModelMixin = RESTFramework::Mixins::ListModelMixin
RESTFramework::ShowModelMixin = RESTFramework::Mixins::ShowModelMixin
RESTFramework::CreateModelMixin = RESTFramework::Mixins::CreateModelMixin
RESTFramework::UpdateModelMixin = RESTFramework::Mixins::UpdateModelMixin
RESTFramework::DestroyModelMixin = RESTFramework::Mixins::DestroyModelMixin
RESTFramework::ReadOnlyModelControllerMixin = RESTFramework::Mixins::ReadOnlyModelControllerMixin
RESTFramework::ModelControllerMixin = RESTFramework::Mixins::ModelControllerMixin
