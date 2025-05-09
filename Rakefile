require_relative "test/config/application"

require "base64"
require "fileutils"

FileUtils.chdir("test")

Rails.application.load_tasks

desc "Update the vendored assets and sync shared css/js."
task :maintain_assets do
  assets_dir = File.expand_path("vendor/assets", __dir__)

  # First, delete js/css directories.
  [ "javascripts", "stylesheets" ].each do |path_type|
    FileUtils.rm_rf(File.expand_path("#{path_type}/rest_framework", assets_dir))
    Dir.mkdir(File.expand_path("#{path_type}/rest_framework", assets_dir))
  end

  # Vendor each asset, summarizing assets into a single `external` asset unless they have
  # `extra_tag_attrs`.
  css_content = ""
  css_path = File.expand_path("stylesheets/#{RESTFramework::EXTERNAL_CSS_NAME}", assets_dir)
  js_content = ""
  js_path = File.expand_path("javascripts/#{RESTFramework::EXTERNAL_JS_NAME}", assets_dir)
  RESTFramework::EXTERNAL_ASSETS.each do |name, cfg|
    file_path = File.expand_path("#{cfg[:place]}/rest_framework/#{name}", assets_dir)

    # Fetch the content.
    content = HTTParty.get(cfg[:url], follow_redirects: true).body.to_s

    # Remove source map references.
    content.gsub!(%r{^//# sourceMappingURL=.*}, "")
    content.gsub!(%r{^/\*# sourceMappingURL=.*}, "")

    # Fix bug in a version of sass where if a css variable refers to a `url`, then it raises an
    # `undefined method 'size' for nil:NilClass` exception in: `sass-3.7.4/lib/sass/util.rb:157`.
    #
    # We fix by simply removing those `url` references. They only appear in Bootstrap, and we don't
    # actually use them.
    if cfg[:place] == "stylesheets"
      vars = []
      content.gsub!(/(--[a-z-]+):\s*url\(".+?"\);?/) {
        vars << Regexp.last_match(1)
        next ""
      }
      vars.each do |var|
        content.gsub!(/var\(#{var}\)/, "none")
      end
    end

    # Inline fonts, if needed.
    if cfg[:inline_fonts]
      base_url = File.dirname(cfg[:url])

      # Replace font URLs with inline and base64-encoded fonts.
      content.gsub!(/url\("([^"]+)"\) format\("([^"]+)"\)/) {
        c = Base64.strict_encode64(HTTParty.get("#{base_url}/#{Regexp.last_match(1)}").body)
        "url(\"data:application/font-#{
          Regexp.last_match(2)
        };charset=utf-8;base64,#{c}\") format(\"#{Regexp.last_match(2)}\")"
      }
    end

    # Normalize content leading/trailing whitespace.
    content = content.strip + "\n"

    if cfg[:extra_tag_attrs].present?
      # If `extra_tag_attrs` is set, then we write the asset to its own file so the tag attributes
      # only affect that particular asset.
      File.write(file_path, content)
    else
      # Otherwise, we append to the external asset.
      if cfg[:place] == "stylesheets"
        css_content << content
      elsif cfg[:place] == "javascripts"
        js_content << content
      else
        raise "Unknown asset place."
      end
    end
  end
  File.write(css_path, css_content)
  File.write(js_path, js_content)
end
