class Api::Plain::RootController < Api::PlainController
  self.description = Api::PlainController::DESCRIPTION

  def root
    render_api({message: Api::PlainController.description})
  end
end
