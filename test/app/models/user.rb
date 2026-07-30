class User < ApplicationRecord
  STATUS_OPTS = {
    "" => "Unknown",
    "online" => "Online",
    "offline" => "Offline",
    "busy" => "Busy",
  }
  include TranslateEnum

  # This association is purposefully named differently than the column to test how this affects the
  # framework.
  belongs_to(:billing_email, optional: true, class_name: "Email", foreign_key: "finance_email_id")

  belongs_to :manager, class_name: "User", optional: true
  has_and_belongs_to_many :movies
  has_many :emails
  has_many :managed_users, class_name: "User", foreign_key: "manager_id"
  has_one :phone_number

  if Rails.gem_version < Gem::Version.new("7.2")
    enum state: { default: 0, pending: 1, banned: 2, archived: 3 }
  else
    enum :state, { default: 0, pending: 1, banned: 2, archived: 3 }
  end
  translate_enum :state

  attribute :secret_number, :integer

  accepts_nested_attributes_for :phone_number, :manager, :billing_email, allow_destroy: true

  validates_presence_of :login
  validates_uniqueness_of :login
  validates_numericality_of :balance, greater_than: 0, allow_nil: true
  validates_inclusion_of :state, in: states.keys
  validates_inclusion_of :state, in: ->(_) { states.keys }
  validates_inclusion_of :state, in: Proc.new { |_| states.keys }
  validates_inclusion_of :status, in: STATUS_OPTS.keys
  validates_inclusion_of :status, in: :status_keys

  def self.status_keys
    STATUS_OPTS.keys
  end

  def status_keys
    self.class.status_keys
  end

  # An example of a "calculated" property method.
  def calculated_property
    5.45
  end

  # An example of a delegated method.
  def delegated
    { login: self.login, is_admin: self.is_admin }
  end

  # Delegation targets exercising argument handling: `**opts` (kwargs), a trailing block after
  # `**opts` (the `:keyrest` must still be detected), and positional args (supplied via `args`).
  def echo_kwargs(**opts)
    opts
  end

  def echo_kwargs_with_block(**opts, &_block)
    opts
  end

  def echo_positional(first, second = nil)
    [ first, second ]
  end

  def returns_nil
    nil
  end

  # Returns an Active Record record so delegation must serialize it through the framework
  # serializer.
  def self_record
    self
  end

  # A private method must never be reachable via delegation.
  private def secret
    "should not be reachable"
  end
  public

  def random1
    rand(100)
  end

  def random2
    rand(100)
  end
end
