class Marble < ApplicationRecord
  belongs_to :user, optional: true

  has_one_attached :picture

  has_rich_text :description

  accepts_nested_attributes_for :user, allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validates_numericality_of :price, greater_than: 0, allow_nil: true

  before_destroy :check_undestroyable

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
