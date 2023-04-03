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

    # Exclude certain classes from being added by default as association fields.
    attr_accessor :exclude_association_classes

    # The default label fields to use when generating labels for `has_many` associations.
    attr_accessor :label_fields

    # The default search columns to use when generating search filters.
    attr_accessor :search_columns

    def initialize
      self.show_backtrace = Rails.env.development?
      self.exclude_association_classes = DEFAULT_EXCLUDE_ASSOCIATION_CLASSES
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
