# == Schema Information
#
# Table name: genres
#
#  id          :integer          not null, primary key
#  description :string           default(""), not null
#  name        :string           default(""), not null
#
# Indexes
#
#  index_genres_on_name  (name) UNIQUE
#
class Genre < ApplicationRecord
  has_and_belongs_to_many :movies
  has_many :main_movies, class_name: "Movie", foreign_key: "main_genre_id"
end
