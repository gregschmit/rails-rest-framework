class Api::Plain::RootController < Api::PlainController
  def root
    render_api({message: Api::PlainController.description})
  end
end
