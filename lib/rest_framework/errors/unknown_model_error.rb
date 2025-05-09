class RESTFramework::Errors::UnknownModelError < RESTFramework::Errors::BaseError
  def initialize(controller_class)
    super()
    @controller_class = controller_class
  end

  def message
    <<~MSG.split("\n").join(" ")
      The model class for `#{@controller_class}` could not be determined. Any controller that
      includes `RESTFramework::BaseModelControllerMixin` (directly or indirectly) must either set
      the `model` attribute on the controller, or the model must be deducible from the controller
      name (e.g., `UsersController` could resolve to the `User` model).
    MSG
  end
end

# Alias for convenience.
RESTFramework::UnknownModelError = RESTFramework::Errors::UnknownModelError
