class PlainApi::RootController < PlainApiController
  def root
    api_response({message: PlainApiController::DESCRIPTION})
  end
end
