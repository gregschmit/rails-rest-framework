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
#
# Indexes
#
#  index_users_on_login  (login) UNIQUE
#
class User < ActiveRecord::Base
  STATUS_OPTS = {
    "" => "Unknown",
    "online" => "Online",
    "offline" => "Offline",
    "busy" => "Busy",
  }
  has_many :things, foreign_key: "owner_id"
  has_and_belongs_to_many :movies

  enum state: {default: 0, pending: 1, banned: 2, archived: 3}

  validates_numericality_of :balance, greater_than: 0, allow_nil: true
  validates_inclusion_of :state, in: states.keys
  validates_inclusion_of :status, in: STATUS_OPTS.keys

  accepts_nested_attributes_for :things, allow_destroy: true

  attribute :secret_number, :integer

  # An example of a "calculated" property method.
  def calculated_property
    return 5.45
  end

  # An example of a delegated method.
  def delegated
    return {login: self.login, is_admin: self.is_admin}
  end
end
