# == Schema Information
#
# Table name: movies
#
#  id         :integer          not null, primary key
#  name       :string           default(""), not null
#  price      :decimal(8, 2)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_movies_on_name  (name) UNIQUE
#
class Movie < ActiveRecord::Base
  has_and_belongs_to_many :users

  has_many_attached :pictures

  validates_numericality_of :price, greater_than: 0, allow_nil: true
end
