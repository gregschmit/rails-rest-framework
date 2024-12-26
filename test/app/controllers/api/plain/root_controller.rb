class Api::Plain::RootController < Api::PlainController
  self.description = Api::PlainController::DESCRIPTION

  def root
    render_api({message: self.class.description})
  end
end
