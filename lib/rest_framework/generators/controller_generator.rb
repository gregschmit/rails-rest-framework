require 'rails/generators'


class RESTFramework::Generators::ControllerGenerator < Rails::Generators::Base
  desc <<~END
    Description:
      Stubs out a active_scaffolded controller. Pass the model name,
      either CamelCased or under_scored.
      The controller name is retrieved as a pluralized version of the model
      name.
      To create a controller within a module, specify the model name as a
      path like 'parent_module/controller_name'.
      This generates a controller class in app/controllers and invokes helper,
      template engine and test framework generators.
    Example:
      `rails generate rest_framework:controller CreditCard`
      Credit card controller with URLs like /credit_card/debit.
          Controller:      app/controllers/credit_cards_controller.rb
          Functional Test: test/functional/credit_cards_controller_test.rb
          Helper:          app/helpers/credit_cards_helper.rb
  END

  def create_controller_file
    create_file "app/controllers/some_controller.rb", "# Add initialization content here"
  end
end
