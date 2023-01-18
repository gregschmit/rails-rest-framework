# == Schema Information
#
# Table name: phone_numbers
#
#  id      :integer          not null, primary key
#  number  :string           default(""), not null
#  user_id :integer          not null
#
# Indexes
#
#  index_phone_numbers_on_number   (number) UNIQUE
#  index_phone_numbers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class PhoneNumber < ApplicationRecord
  belongs_to :user
end
