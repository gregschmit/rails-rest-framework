class Thing < ActiveRecord::Base
  validates_numericality_of :price, greater_than: 0, allow_nil: true
end
