# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  age        :integer
#  balance    :decimal(8, 2)
#  is_admin   :boolean          default(FALSE)
#  login      :string           default(""), not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_users_on_login  (login) UNIQUE
#
class User < ActiveRecord::Base
  has_many :things, foreign_key: "owner_id"
  has_and_belongs_to_many :movies

  validates_numericality_of :balance, greater_than: 0, allow_nil: true

  accepts_nested_attributes_for :things, allow_destroy: true

  # An example of a "calculated" property method.
  def calculated_property
    return 5.45
  end

  # An example of a delegated method.
  def delegated
    return {login: self.login, is_admin: self.is_admin}
  end
end
