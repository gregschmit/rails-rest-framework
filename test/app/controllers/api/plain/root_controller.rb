class Api::Plain::RootController < Api::PlainController
  def root
    api_response({message: Api::PlainController::DESCRIPTION})
  end
end
