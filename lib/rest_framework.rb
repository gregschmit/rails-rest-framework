# frozen_string_literal: true

module RESTFramework
  BUILTIN_ACTIONS = {
    index: :get,
    new: :get,
    create: :post,
  }.freeze
  BUILTIN_MEMBER_ACTIONS = {
    show: :get,
    edit: :get,
    update: [:put, :patch].freeze,
    destroy: :delete,
  }.freeze
  RRF_BUILTIN_ACTIONS = {
    options: :options,
  }.freeze
  RRF_BUILTIN_BULK_ACTIONS = {
    update_all: [:put, :patch].freeze,
    destroy_all: :delete,
  }.freeze

  # We put most vendored external assets into these files to make precompilation and serving faster.
  EXTERNAL_CSS_NAME = "rest_framework/external.min.css"
  EXTERNAL_JS_NAME = "rest_framework/external.min.js"

  # We should always add the `.min` extension prefix even if the assets are not minified, to avoid
  # sprockets minifying the assets. We target propshaft, so we want these assets to just be passed
  # through.
  # rubocop:disable Layout/LineLength
  EXTERNAL_ASSETS = {
    # Bootstrap
    "bootstrap.min.css" => {
      url: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
      sri: "sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH",
    },
    "bootstrap.min.js" => {
      url: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js",
      sri: "sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz",
    },

    # Bootstrap Icons
    "bootstrap-icons.min.css" => {
      url: "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css",
      inline_fonts: true,
    },

    # Highlight.js
    "highlight.min.js" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.0/highlight.min.js",
      sri: "sha512-6QBAC6Sxc4IF04SvIg0k78l5rP5YgVjmHX2NeArelbxM3JGj4imMqfNzEta3n+mi7iG3nupdLnl3QrbfjdXyTg==",
    },
    "highlight-json.min.js" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.0/languages/json.min.js",
      sri: "sha512-8JO7/pRnd1Ce8OBXWQg85e5wNPJdBaQdN8w4oDa+HelMXaLwCxTdbzdWHmJtWR9AmcI6dOln4FS5/KrzpxqqfQ==",
    },
    "highlight-xml.min.js" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.0/languages/xml.min.js",
      sri: "sha512-/vq6wbS2Qkv8Hj4mP3Jd/m6MbnIrquzZiUt9tIluQfe332IQeFDrSIK7j2cjAyn6/9Ntb2WMPbo1CAxu26NViA==",
    },
    "highlight-a11y-dark.min.css" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.0/styles/a11y-dark.min.css",
      sri: "sha512-Vj6gPCk8EZlqnoveEyuGyYaWZ1+jyjMPg8g4shwyyNlRQl6d3L9At02ZHQr5K6s5duZl/+YKMnM3/8pDhoUphg==",
      extra_tag_attrs: {class: "rrf-dark-mode"},
    },
    "highlight-a11y-light.min.css" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.0/styles/a11y-light.min.css",
      sri: "sha512-WDk6RzwygsN9KecRHAfm9HTN87LQjqdygDmkHSJxVkVI7ErCZ8ZWxP6T8RvBujY1n2/E4Ac+bn2ChXnp5rnnHA==",
      extra_tag_attrs: {class: "rrf-light-mode"},
    },

    # NeatJSON
    "neatjson.min.js" => {
      url: "https://cdn.jsdelivr.net/npm/neatjson@0.10.6/javascript/neatjson.min.js",
      exclude_from_docs: true,
    },

    # Trix
    "trix.min.css" => {
      url: "https://unpkg.com/trix@2.0.8/dist/trix.css",
      exclude_from_docs: true,
    },
    "trix.min.js" => {
      url: "https://unpkg.com/trix@2.0.8/dist/trix.umd.min.js",
      exclude_from_docs: true,
    },
  }.map { |name, cfg|
    ext = File.extname(name)
    if ext == ".js"
      cfg[:place] = "javascripts"
      cfg[:extra_tag_attrs] ||= {}
      cfg[:tag_attrs] = {
        src: cfg[:url],
        integrity: cfg[:sri],
        crossorigin: "anonymous",
        referrerpolicy: "no-referrer",
        defer: true,
        **cfg[:extra_tag_attrs],
      }
      cfg[:tag] = ActionController::Base.helpers.tag.script(**cfg[:tag_attrs])
    elsif ext == ".css"
      cfg[:place] = "stylesheets"
      cfg[:extra_tag_attrs] ||= {}
      cfg[:tag_attrs] = {
        rel: "stylesheet",
        href: cfg[:url],
        integrity: cfg[:sri],
        crossorigin: "anonymous",
        **cfg[:extra_tag_attrs],
      }
      cfg[:tag] = ActionController::Base.helpers.tag.link(**cfg[:tag_attrs])
    else
      raise "Unknown asset extension: #{ext}."
    end

    [name, cfg]
  }.to_h.freeze
  # rubocop:enable Layout/LineLength

  EXTERNAL_UNSUMMARIZED_ASSETS = EXTERNAL_ASSETS.select { |_, cfg| cfg[:extra_tag_attrs].present? }

  # Global configuration should be kept minimal, as controller-level configurations allows multiple
  # APIs to be defined to behave differently.
  class Config
    DEFAULT_LABEL_FIELDS = %w(name label login title email username url).freeze
    DEFAULT_SEARCH_COLUMNS = DEFAULT_LABEL_FIELDS + %w(description note).freeze
    DEFAULT_EXCLUDE_BODY_FIELDS = %w[
      created_at
      created_by
      created_by_id
      updated_at
      updated_by
      updated_by_id
      _method
      utf8
      authenticity_token
    ].freeze

    # Do not run `rrf_finalize` on controllers automatically using a `TracePoint` hook. This is a
    # performance option and must be global because we have to determine this before any
    # controller-specific configuration is set. If this is set to `true`, then you must manually
    # call `rrf_finalize` after any configuration on each controller that needs to participate
    # in:
    #  - Model delegation, for the helper methods to be defined dynamically.
    #  - Websockets, for `::Channel` class to be defined dynamically.
    #  - Controller configuration freezing.
    attr_accessor :disable_auto_finalize

    # Freeze configuration attributes during finalization to prevent accidental mutation.
    attr_accessor :freeze_config

    # Specify reverse association tables that are typically very large, and therefore should not be
    # added to fields by default.
    attr_accessor :large_reverse_association_tables

    # Whether the backtrace should be shown in rescued errors.
    attr_accessor :show_backtrace

    # Disable `rescue_from` on the controller mixins.
    attr_accessor :disable_rescue_from

    # The default label fields to use when generating labels for `has_many` associations.
    attr_accessor :label_fields

    # The default search columns to use when generating search filters.
    attr_accessor :search_columns

    # The default list of fields to exclude from the body of the request.
    attr_accessor :exclude_body_fields

    # Option to use vendored assets (requires sprockets or propshaft) rather than linking to
    # external assets (the default).
    attr_accessor :use_vendored_assets

    def initialize
      self.show_backtrace = Rails.env.development?
      self.label_fields = DEFAULT_LABEL_FIELDS
      self.search_columns = DEFAULT_SEARCH_COLUMNS
      self.exclude_body_fields = DEFAULT_EXCLUDE_BODY_FIELDS
    end
  end

  def self.config
    return @config ||= Config.new
  end

  def self.configure
    yield(self.config)
  end

  def self.features
    return @features ||= {}
  end
end

require_relative "rest_framework/engine"
require_relative "rest_framework/errors"
require_relative "rest_framework/filters"
require_relative "rest_framework/generators"
require_relative "rest_framework/mixins"
require_relative "rest_framework/paginators"
require_relative "rest_framework/routers"
require_relative "rest_framework/serializers"
require_relative "rest_framework/utils"
require_relative "rest_framework/version"
