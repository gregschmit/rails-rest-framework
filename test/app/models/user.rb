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
class User < ActiveRecord::Base
  STATUS_OPTS = {
    "" => "Unknown",
    "online" => "Online",
    "offline" => "Offline",
    "busy" => "Busy",
  }
  has_many :marbles, foreign_key: "user_id"
  has_and_belongs_to_many :movies

  enum state: {default: 0, pending: 1, banned: 2, archived: 3}

  validates_numericality_of :balance, greater_than: 0, allow_nil: true
  validates_inclusion_of :state, in: states.keys
  validates_inclusion_of :status, in: STATUS_OPTS.keys

  accepts_nested_attributes_for :marbles, allow_destroy: true

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
