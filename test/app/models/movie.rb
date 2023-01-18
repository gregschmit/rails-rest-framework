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
  belongs_to :main_genre, class_name: "Genre"
  has_and_belongs_to_many :genres
  has_and_belongs_to_many :users

  has_many_attached :pictures

  validates_numericality_of :price, greater_than: 0, allow_nil: true
end
