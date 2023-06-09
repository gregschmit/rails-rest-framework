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

  # rubocop:disable Layout/LineLength
  EXTERNAL_ASSETS = {
    # Bootstrap
    "bootstrap.css" => {
      url: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha2/dist/css/bootstrap.min.css",
      sri: "sha384-aFq/bzH65dt+w6FI2ooMVUpc+21e0SRygnTpmBvdBgSdnuTN7QbdgL+OapgHtvPp",
    },
    "bootstrap.js" => {
      url: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha2/dist/js/bootstrap.bundle.min.js",
      sri: "sha384-qKXV1j0HvMUeCBQ+QVp7JcfGl760yU08IQ+GpUo5hlbpg51QRiuqHAJz8+BrxE/N",
    },

    # Bootstrap Icons
    "bootstrap-icons.css" => {
      url: "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.4/font/bootstrap-icons.min.css",
      inline_fonts: true,
    },

    # Highlight.js
    "highlight.js" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/highlight.min.js",
      sri: "sha512-bgHRAiTjGrzHzLyKOnpFvaEpGzJet3z4tZnXGjpsCcqOnAH6VGUx9frc5bcIhKTVLEiCO6vEhNAgx5jtLUYrfA==",
    },
    "highlight-json.js" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/languages/json.min.js",
      sri: "sha512-0xYvyncS9OLE7GOpNBZFnwyh9+bq4HVgk4yVVYI678xRvE22ASicF1v6fZ1UiST+M6pn17MzFZdvVCI3jTHSyw==",
    },
    "highlight-xml.js" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/languages/xml.min.js",
      sri: "sha512-5zBcw+OKRkaNyvUEPlTSfYylVzgpi7KpncY36b0gRudfxIYIH0q0kl2j26uCUB3YBRM6ytQQEZSgRg+ZlBTmdA==",
    },
    "highlight-a11y-dark.css" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/styles/a11y-dark.min.css",
      sri: "sha512-Vj6gPCk8EZlqnoveEyuGyYaWZ1+jyjMPg8g4shwyyNlRQl6d3L9At02ZHQr5K6s5duZl/+YKMnM3/8pDhoUphg==",
      extra_tag_attrs: {class: "rrf-dark-mode"},
    },
    "highlight-a11y-light.css" => {
      url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/styles/a11y-light.min.css",
      sri: "sha512-WDk6RzwygsN9KecRHAfm9HTN87LQjqdygDmkHSJxVkVI7ErCZ8ZWxP6T8RvBujY1n2/E4Ac+bn2ChXnp5rnnHA==",
      extra_tag_attrs: {class: "rrf-light-mode"},
    },

    # NeatJSON
    "neatjson.js" => {
      url: "https://cdn.jsdelivr.net/npm/neatjson@0.10.5/javascript/neatjson.min.js",
      exclude_from_docs: true,
    },

    # Trix
    "trix.css" => {
      url: "https://unpkg.com/trix@2.0.0/dist/trix.css",
      exclude_from_docs: true,
    },
    "trix.js" => {
      url: "https://unpkg.com/trix@2.0.0/dist/trix.umd.min.js",
      exclude_from_docs: true,
    },
  }.map { |name, cfg|
    if File.extname(name) == ".js"
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
    else
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
    end

    [name, cfg]
  }.to_h.freeze
  # rubocop:enable Layout/LineLength

  # Global configuration should be kept minimal, as controller-level configurations allows multiple
  # APIs to be defined to behave differently.
  class Config
    DEFAULT_EXCLUDE_ASSOCIATION_CLASSES = [].freeze
    DEFAULT_LABEL_FIELDS = %w(name label login title email username url).freeze
    DEFAULT_SEARCH_COLUMNS = DEFAULT_LABEL_FIELDS + %w(description note).freeze

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

    # Specify reverse association tables that are typically very large, andd therefore should not be
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

    # Option to use vendored assets (requires sprockets or propshaft) rather than linking to
    # external assets (the default).
    attr_accessor :use_vendored_assets

    def initialize
      self.show_backtrace = Rails.env.development?
      self.label_fields = DEFAULT_LABEL_FIELDS
      self.search_columns = DEFAULT_SEARCH_COLUMNS
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

require_relative "rest_framework/controller_mixins"
require_relative "rest_framework/engine"
require_relative "rest_framework/errors"
require_relative "rest_framework/filters"
require_relative "rest_framework/generators"
require_relative "rest_framework/paginators"
require_relative "rest_framework/routers"
require_relative "rest_framework/serializers"
require_relative "rest_framework/utils"
require_relative "rest_framework/version"
