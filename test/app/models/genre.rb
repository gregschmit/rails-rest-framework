class Genre < ApplicationRecord
  has_and_belongs_to_many :movies
  has_many :main_movies, class_name: "Movie", foreign_key: "main_genre_id"
end
