# == Schema Information
#
# Table name: emails
#
#  id         :integer          not null, primary key
#  email      :string           default(""), not null
#  is_primary :boolean          default(FALSE), not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_emails_on_email    (email) UNIQUE
#  index_emails_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class Email < ApplicationRecord
  belongs_to :user
end
