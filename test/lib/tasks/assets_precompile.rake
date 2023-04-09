# Because we don't use sprockets, we overload `assets:precompile` to stamp the version from git
# so Heroku has the framework version available.
namespace :assets do
  desc "Overloaded `assets:precompile` task to stamp the version from git."
  task :precompile do
    system("echo 'gns: test before asssets precompile hook'")
    system("pwd")
    system("git status")
  end
end
