require "test_helper"

# `RESTFramework::Utils.controller_for_model` finds the REST controller for a model at the same
# namespace level as the current controller — the basis of association-expansion allowlists.
class RRFControllerForModelTest < ActiveSupport::TestCase
  def controller_for(current, model)
    RESTFramework::Utils.controller_for_model(current, model)
  end

  def test_resolves_a_self_referential_sibling
    # `Api::Test::AssocExp::UsersController` has model User, so it discovers itself for User.
    assert_equal(
      Api::Test::AssocExp::UsersController,
      controller_for(Api::Test::AssocExp::UsersController, User),
    )
  end

  def test_resolves_a_sibling_at_the_same_namespace
    # `Api::Demo::MoviesController` + Genre => `Api::Demo::GenresController`.
    assert_equal(
      Api::Demo::GenresController,
      controller_for(Api::Demo::MoviesController, Genre),
    )
  end

  def test_returns_nil_when_no_sibling_controller_exists
    # There is no controller for Email under `Api::Test::AssocExp`.
    assert_nil(controller_for(Api::Test::AssocExp::UsersController, Email))
  end

  def test_returns_nil_for_an_anonymous_controller
    assert_nil(controller_for(Class.new, User))
  end
end
