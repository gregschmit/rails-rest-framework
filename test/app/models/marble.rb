# == Schema Information
#
# Table name: marbles
#
#  id            :integer          not null, primary key
#  is_discounted :boolean          default(FALSE)
#  name          :string           default(""), not null
#  price         :decimal(6, 2)
#  radius_mm     :integer          default(1), not null
#  created_at    :datetime
#  updated_at    :datetime
#  user_id       :integer
#
# Indexes
#
#  index_marbles_on_name     (name) UNIQUE
#  index_marbles_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class Marble < ApplicationRecord
  belongs_to :user

  has_one_attached :picture

  has_rich_text :description

  accepts_nested_attributes_for :user, allow_destroy: true

  validates_presence_of :name
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
