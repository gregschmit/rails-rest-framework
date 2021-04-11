# Do not use Rails-specific helper methods here (e.g., `blank?`) so the module can run standalone.
module RESTFramework
  module Version
    VERSION_FILEPATH = File.expand_path("../../VERSION", __dir__)

    def self.get_version(skip_git: false)
      # First, attempt to get the version from git.
      unless skip_git
        version = `git describe --dirty --broken 2>/dev/null`&.strip
        return version unless !version || version.empty?
      end

      # Git failed or was skipped, so try to find a VERSION file.
      begin
        version = File.read(VERSION_FILEPATH)&.strip
        return version unless !version || version.blank?
      rescue SystemCallError
      end

      # No VERSION file, so version is unknown.
      return 'unknown'
    end

    def self.stamp_version
      File.write(VERSION_FILEPATH, RESTFramework::VERSION)
    end

    def self.unstamp_version
      File.delete(VERSION_FILEPATH) if File.exist?(VERSION_FILEPATH)
    end
  end

  VERSION = Version.get_version()
end
