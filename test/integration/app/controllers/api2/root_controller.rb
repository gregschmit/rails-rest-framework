class Api2::RootController < Api2Controller
  def root
    api_response({message: "Welcome to your custom API2 root!"})
  end
end
