require_relative "test/config/application"

require "base64"
require "fileutils"

FileUtils.chdir("test")

Rails.application.load_tasks

desc "Update the vendored assets."
task :vendor_assets do
  assets_dir = File.expand_path("vendor/assets", __dir__)

  # First, delete js/css directories.
  ["javascripts", "stylesheets"].each do |path_type|
    FileUtils.rm_rf(File.expand_path("#{path_type}/rest_framework", assets_dir))
    Dir.mkdir(File.expand_path("#{path_type}/rest_framework", assets_dir))
  end

  # Fetch each asset.
  RESTFramework::EXTERNAL_ASSETS.each do |name, cfg|
    file_path = File.expand_path("#{cfg[:place]}/rest_framework/#{name}", assets_dir)
    File.open(file_path, "wb") do |file|
      HTTParty.get(cfg[:url], stream_body: true, follow_redirects: true) do |fragment|
        file.write(fragment)
      end
    end

    # Inline fonts, if needed.
    if cfg[:inline_fonts]  # rubocop:disable Style/Next
      base_url = File.dirname(cfg[:url])

      # Replace font URLs with inline and base64-encoded fonts.
      new_file = File.read(file_path).gsub(/url\("([^"]+)"\) format\("([^"]+)"\)/) {
        content = Base64.strict_encode64(HTTParty.get("#{base_url}/#{Regexp.last_match(1)}").body)
        "url(\"data:application/font-#{
          Regexp.last_match(2)
        };charset=utf-8;base64,#{content}\") format(\"#{Regexp.last_match(2)}\")"
      }
      File.write(file_path, new_file)
    end
  end
end
