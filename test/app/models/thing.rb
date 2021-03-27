class Thing < ActiveRecord::Base
  if Rails::VERSION::MAJOR >= 5
    belongs_to :owner, class_name: 'User', optional: true
  else
    belongs_to :owner, class_name: 'User'
  end

  validates_numericality_of :price, greater_than: 0, allow_nil: true

  # An example of a "cauculated" property method.
  def calculated_property
    return 9.234
  end
end
