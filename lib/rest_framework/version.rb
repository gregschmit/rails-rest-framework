module RESTFramework
  module Version
    def self.get_version(skip_git: false)
      # First, attempt to get the version from git.
      unless skip_git
        begin
          version = `git describe --dirty --broken 2>/dev/null`.strip
          raise "blank version" if version.blank?
          return version unless version.blank?
        rescue
        end
      end

      # Git failed or was skipped, so try to find a VERSION file.
      begin
        version = File.read(File.expand_path("../../VERSION", __dir__))
        return version unless version.blank?
      rescue
      end

      # No VERSION file, so version is unknown.
      return '0.unknown'
    end
  end

  VERSION = Version.get_version()
end
