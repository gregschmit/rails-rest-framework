require "rails/generators"

# Most projects don't have the inflection "REST" as an acronym, so this is a helper class to prevent
# this generator from being namespaced under `r_e_s_t_framework`.
# :nocov:
class RESTFrameworkCustomGeneratorControllerNamespace < String
  def camelize
    return "RESTFramework"
  end
end
# :nocov:

class RESTFramework::Generators::ControllerGenerator < Rails::Generators::Base
  PATH_REGEX = /^[a-z0-9][a-z0-9_]+$/

  desc <<~END
    Description:
      Generates a new REST Framework controller.

      Specify the controller as a path, including the module, if needed, like:
      'parent_module/controller_name'.

    Example:
      `rails generate rest_framework:controller user_api/groups`

      Generates a controller at `app/controllers/user_api/groups_controller.rb` named
      `UserApi::GroupsController`.
  END

  argument :path, type: :string
  class_option(
    :parent_class, type: :string, default: "ApplicationController", desc: "Inheritance parent"
  )
  class_option(
    :include_base,
    type: :boolean,
    default: false,
    desc: "Include `BaseControllerMixin`, not `ModelControllerMixin`",
  )

  # Some projects may not have the inflection "REST" as an acronym, which changes this generator to
  # be namespaced in `r_e_s_t_framework`, which is weird.
  def self.namespace
    return RESTFrameworkCustomGeneratorControllerNamespace.new("rest_framework:controller")
  end

  def create_rest_controller_file
    unless PATH_REGEX.match?(self.path)
      raise StandardError, "Path isn't valid."
    end

    # Remove '_controller' from end of path, if it exists.
    cleaned_path = self.path.delete_suffix("_controller")

    content = <<~END
      class #{cleaned_path.camelize}Controller < #{options[:parent_class]}
        include RESTFramework::#{
          options[:include_base] ? "BaseControllerMixin" : "ModelControllerMixin"
        }
      end
    END
    create_file("app/controllers/#{cleaned_path}_controller.rb", content)
  end
end
