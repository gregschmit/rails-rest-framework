class User < ActiveRecord::Base
  has_many :things, foreign_key: "owner_id"

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
