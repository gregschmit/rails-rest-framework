# == Schema Information
#
# Table name: movies
#
#  id            :integer          not null, primary key
#  name          :string           default(""), not null
#  price         :decimal(8, 2)
#  created_at    :datetime
#  updated_at    :datetime
#  main_genre_id :integer
#
# Indexes
#
#  index_movies_on_main_genre_id  (main_genre_id)
#  index_movies_on_name           (name) UNIQUE
#
# Foreign Keys
#
#  main_genre_id  (main_genre_id => genres.id) ON DELETE => nullify
#
class Movie < ApplicationRecord
  belongs_to :main_genre, optional: true, class_name: "Genre"
  has_and_belongs_to_many :genres
  has_and_belongs_to_many :users

  has_rich_text :description

  has_one_attached :cover
  has_many_attached :pictures

  validates_numericality_of :price, greater_than: 0, allow_nil: true

  def self.ransackable_attributes(*args)
    return %w(name price created_at updated_at)
  end

  def self.ransackable_associations(*args)
    return []
  end
end
