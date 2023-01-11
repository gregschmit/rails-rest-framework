# == Schema Information
#
# Table name: things
#
#  id            :integer          not null, primary key
#  is_discounted :boolean          default(FALSE)
#  name          :string           default(""), not null
#  price         :decimal(6, 2)
#  shape         :string
#  created_at    :datetime
#  updated_at    :datetime
#  owner_id      :integer
#
# Indexes
#
#  index_things_on_name      (name) UNIQUE
#  index_things_on_owner_id  (owner_id)
#
# Foreign Keys
#
#  owner_id  (owner_id => users.id) ON DELETE => cascade
#
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
