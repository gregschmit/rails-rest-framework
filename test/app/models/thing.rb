class Thing < ActiveRecord::Base
  if Rails::VERSION::MAJOR >= 5
    belongs_to :owner, class_name: 'User', optional: true
  else
    belongs_to :owner, class_name: 'User'
  end

  before_destroy :check_undestroyable
  before_save :check_unsaveable

  validates_numericality_of :price, greater_than: 0, allow_nil: true

  # An example of a "calculated" property method.
  def calculated_property
    return 9.234
  end

  protected

  def check_undestroyable
    if self.name == 'An Undestroyable Thing'
      errors.add(:base, "This record is undestroyable.")
      throw(:abort)
    end
  end

  def check_unsaveable
    if self.name == 'An Unsaveable Thing'
      errors.add(:base, "This record is unsaveable.")
      throw(:abort)
    end
  end
end
