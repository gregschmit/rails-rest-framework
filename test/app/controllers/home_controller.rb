class HomeController < ApplicationController
  layout "rest_framework"

  before_action do
    @hide_breadcrumbs = true
    @hide_heading = true
    @hide_request_metadata = true
  end

  def index
    render_content(Rails.root.join("../README.md"))
  end

  def guide_first
    redirect_to(show_guide_section_path(section: self.get_sections.first[0]))
  end

  def show_guide_section
    render_content(self.lookup_section(params[:section]))
  end

  def send_guide_asset
    send_file(self.lookup_section(params[:section], asset: params[:asset]))
  end

  protected

  def render_content(path)
    file_content = File.read(path)

    # If there is no trailing slash, adjust relative asset links.
    original_path = URI(request.original_fullpath).path
    unless URI(request.original_fullpath).path.end_with?("/")
      last_element = original_path.split("/").last
      file_content.gsub!(/]\(assets\//, "](#{last_element}/assets/")
    end

    @content = Kramdown::Document.new(file_content, input: "GFM", hard_wrap: false)
    render(template: "home/markdown")
  end

  def lookup_section(section, asset: nil)
    if path = self.get_sections.dig(section, :path)
      if asset
        f = File.join(path, "assets/#{asset}")
        return f if File.exist?(f)
      else
        return File.join(path, "index.md")
      end
    end

    raise AbstractController::ActionNotFound
  end

  def get_sections
    return Dir.glob(Rails.root.join("../guide/*")).map { |path|
      next nil unless match = path.match(/[0-9]_([a-z_]+)$/)

      title = File.read(File.join(path, "index.md")).match(/^# (.*)$/)[1]
      next [match[1], {path: path, title: title}]
    }.compact.to_h
  end
  helper_method :get_sections
end
