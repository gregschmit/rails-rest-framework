class Api::Demo::MoviesController < Api::DemoController
  self.model = Movie

  add_action(
    :random,
    :get,
    type: :collection,
    metadata: { description: "Get a random number.", method: "Dice roll." },
  )
  add_action(
    :random,
    :get,
    type: :member,
    metadata: {
      description: "Get a random number for this record.",
      method: "Still a dice roll.",
    },
  )

  def random
    render(api: { number: 4, message: "Chosen by fair dice roll. Guaranteed to be random." })
  end
end
