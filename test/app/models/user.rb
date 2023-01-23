# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  age        :integer
#  balance    :decimal(8, 2)
#  is_admin   :boolean          default(FALSE)
#  login      :string           default(""), not null
#  state      :integer          default("default"), not null
#  status     :string           default(""), not null
#  created_at :datetime
#  updated_at :datetime
#  manager_id :integer
#
# Indexes
#
#  index_users_on_login       (login) UNIQUE
#  index_users_on_manager_id  (manager_id)
#
# Foreign Keys
#
#  manager_id  (manager_id => users.id) ON DELETE => nullify
#
class User < ApplicationRecord
  STATUS_OPTS = {
    "" => "Unknown",
    "online" => "Online",
    "offline" => "Offline",
    "busy" => "Busy",
  }
  belongs_to :manager, class_name: "User", optional: true
  has_and_belongs_to_many :movies
  has_many :emails
  has_many :managed_users, class_name: "User", foreign_key: "manager_id"
  has_many :marbles, foreign_key: "user_id"
  has_one :phone_number

  enum state: {default: 0, pending: 1, banned: 2, archived: 3}

  attribute :secret_number, :integer

  accepts_nested_attributes_for :marbles, :phone_number, allow_destroy: true
  accepts_nested_attributes_for :phone_number, allow_destroy: true

  validates_numericality_of :balance, greater_than: 0, allow_nil: true
  validates_inclusion_of :state, in: states.keys
  validates_inclusion_of :status, in: :status_keys

  # Adding this class method to test serializing inclusion symbol in `OPTIONS` endpoint.
  def self.status_keys
    return STATUS_OPTS.keys
  end

  def status_keys
    return self.class.status_keys
  end

  # An example of a "calculated" property method.
  def calculated_property
    return 5.45
  end

  # An example of a delegated method.
  def delegated
    return {login: self.login, is_admin: self.is_admin}
  end
end
