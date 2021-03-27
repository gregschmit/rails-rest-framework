class User < ActiveRecord::Base
  has_many :things, foreign_key: 'owner_id'

  validates_numericality_of :balance, greater_than: 0, allow_nil: true

  # An example of a "cauculated" property method.
  def calculated_property
    return 5.45
  end
end
