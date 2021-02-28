class User < ActiveRecord::Base
  has_many :things

  validates_numericality_of :balance, greater_than: 0, allow_nil: true
end
