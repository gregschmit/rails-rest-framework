module RESTFramework
  module Version
    @_version = nil

    def self.get_version
      # Return cached @_version, if available.
      return @_version if @_version

      # First, attempt to get the version from git.
      begin
        version = `git describe`.strip
        raise "blank version" if version.nil? || version.match(/^\w*$/)
        # Check for local changes.
        changes = `git status --porcelain`
        version << '.localchanges' if changes.strip.length > 0
        return version
      rescue
      end

      # Git failed, so try to find a VERSION_STAMP.
      begin
        version = File.read(File.expand_path("VERSION_STAMP", __dir__))
        unless version.nil? || version.match(/^\w*$/)
          return (@_version = version)  # cache VERSION_STAMP content in @_version
        end
      rescue
      end

      # No VERSION_STAMP, so version is unknown.
      return '0.unknown'
    end
  end

  VERSION = Version.get_version()
end
