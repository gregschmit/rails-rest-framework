class Thing < ActiveRecord::Base
  if Rails::VERSION::MAJOR >= 5
    belongs_to :owner, optional: true
  else
    belongs_to :owner
  end

  validates_numericality_of :price, greater_than: 0, allow_nil: true
end
