class Api::Plain::RootController < Api::PlainController
  self.description = Api::PlainController::DESCRIPTION

  def root
    render(api: { message: self.class.description })
  end
end
