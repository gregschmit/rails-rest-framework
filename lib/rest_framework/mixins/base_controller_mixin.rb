module RESTFramework::Mixins::BaseControllerMixin
  def self.included(base)
    RESTFramework.deprecator.warn(
      "BaseControllerMixin is deprecated; use RESTFramework::Controller instead.",
    )

    base.include(RESTFramework::Controller)
  end
end

# Alias for convenience.
RESTFramework::BaseControllerMixin = RESTFramework::Mixins::BaseControllerMixin
