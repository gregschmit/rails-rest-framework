class Star < ApplicationRecord
  belongs_to :user

  # A user's star points polymorphically to a `Movie` or a `Genre`.
  belongs_to :starrable, polymorphic: true
end
