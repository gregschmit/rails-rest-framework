class Api::Test::NetworkController < Api::TestController
  self.description = "A non-model controller demonstrating a modelless, extra-action route."
  add_action(:test, :get)

  def test
    render(api: { message: "Hello, this is your non-model route!" })
  end
end
