class Email < ApplicationRecord
  belongs_to :user, optional: true
  has_one :billing_user, class_name: "User", inverse_of: :billing_email
end
