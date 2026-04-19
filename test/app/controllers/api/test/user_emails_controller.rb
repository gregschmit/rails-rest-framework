class Api::Test::UserEmailsController < Api::TestController
  self.model = Email
  self.bulk = :raw

  def get_recordset
    User.find(params[:user_id]).emails
  end
end
