module RESTFramework
  # Do not use Rails-specific helper methods here (e.g., `blank?`) so the module can run standalone.
  module Version
    VERSION_FILEPATH = File.expand_path("../../VERSION", __dir__)
    UNKNOWN = "0-unknown"

    def self.get_version(skip_git: false)
      # First, attempt to get the version from git.
      unless skip_git
        version = `git describe --dirty 2>/dev/null`&.strip
        return version unless !version || version.empty?
      end

      # Git failed or was skipped, so try to find a VERSION file.
      begin
        version = File.read(VERSION_FILEPATH)&.strip
        return version unless !version || version.empty?
      rescue SystemCallError
      end

      # No VERSION file, so version is unknown.
      UNKNOWN
    end

    def self.stamp_version(version = nil)
      # Stamp the given version into the VERSION file, deriving it from git when none is provided.
      # Returns the stamped version so callers don't rely on the (require-time) `VERSION` constant.
      version ||= self.get_version
      if version != UNKNOWN
        File.write(VERSION_FILEPATH, version)
      end
      version
    end

    def self.unstamp_version
      File.delete(VERSION_FILEPATH) if File.exist?(VERSION_FILEPATH)
    end
  end

  VERSION = Version.get_version(skip_git: true)
end
