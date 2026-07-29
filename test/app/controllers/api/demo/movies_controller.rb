class Api::Demo::MoviesController < Api::DemoController
  self.model = Movie

  add_collection_action(
    :random, :get, metadata: { description: "Get a random number.", method: "Dice roll." }
  )
  add_member_action(
    :random,
    :get,
    metadata: {
      description: "Get a random number for this record.",
      method: "Still a dice roll.",
    },
  )

  def random
    render(api: { number: 4, message: "Chosen by fair dice roll. Guaranteed to be random." })
  end
end
