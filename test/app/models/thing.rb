class Thing < ActiveRecord::Base
  if Rails::VERSION::MAJOR >= 5
    belongs_to :owner, class_name: "User", optional: true
  else
    belongs_to :owner, class_name: "User"
  end

  before_destroy :check_undestroyable

  validates_numericality_of :price, greater_than: 0, allow_nil: true

  accepts_nested_attributes_for :owner, allow_destroy: true

  # An example of a "calculated" property method.
  def calculated_property
    return 9.234
  end

  def check_undestroyable
    if self.name == "Undestroyable"
      errors.add(:base, "This record is undestroyable.")
      throw(:abort)
    end
  end
end
