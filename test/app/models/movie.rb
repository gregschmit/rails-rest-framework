class Movie < ApplicationRecord
  belongs_to :main_genre, optional: true, class_name: "Genre"
  has_and_belongs_to_many :genres
  has_and_belongs_to_many :users

  has_rich_text :description

  has_one_attached :cover
  has_many_attached :pictures

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_numericality_of :price, greater_than: 0, allow_nil: true

  attribute :default_discount, :decimal, default: 5.0

  def self.ransackable_attributes(*args)
    return %w(name price created_at updated_at)
  end

  def self.ransackable_associations(*args)
    return []
  end

  before_destroy do
    if self.name == "Undestroyable"
      errors.add(:base, "This record is undestroyable.")
      throw(:abort)
    end
  end
end
