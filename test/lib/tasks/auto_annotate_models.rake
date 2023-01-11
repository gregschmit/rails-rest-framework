# NOTE: only doing this in development as some production environments (Heroku)
# NOTE: are sensitive to local FS writes, and besides -- it's just not proper
# NOTE: to have a dev-mode tool do its thing in production.
if Rails.env.development?
  require "annotate"
  task :set_annotation_options do
    # You can override any of these by setting an environment variable of the
    # same name.
    Annotate.set_defaults(
      "models"                      => "true",
      "show_foreign_keys"           => "true",
      "show_complete_foreign_keys"  => "true",
      "show_indexes"                => "true",
      "exclude_tests"               => "true",
      "exclude_fixtures"            => "true",
      "exclude_factories"           => "true",
      "exclude_serializers"         => "true",
      "exclude_scaffolds"           => "true",
      "exclude_controllers"         => "true",
      "exclude_helpers"             => "true",
      "exclude_sti_subclasses"      => "true",
      "format_bare"                 => "true",
      "sort"                        => "true",
      "classified_sort"             => "true",
      "with_comment"                => "true",
    )
  end

  Annotate.load_tasks
end
