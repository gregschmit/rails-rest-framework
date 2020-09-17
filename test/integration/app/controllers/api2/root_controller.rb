class Api2::RootController < Api2Controller
  def root
    render inline: "Test successful on API2!"
  end
end
