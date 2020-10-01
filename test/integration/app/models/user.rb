class User < ActiveRecord::Base
  validates_numericality_of :balance, greater_than: 0, allow_nil: true
end
