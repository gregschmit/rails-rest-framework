class Api::Demo::MoviesController < Api::DemoController
  include RESTFramework::BulkModelControllerMixin

  self.extra_actions = {
    random: {
      methods: [:get], metadata: {description: "Get a random number.", method: "Dice roll."}
    },
  }

  self.extra_member_actions = {
    random: {
      methods: :get,
      metadata: {description: "Get a random number for this record.", method: "Still a dice roll."},
    },
  }

  def random
    render_api({number: 4, message: "Chosen by fair dice roll. Guaranteed to be random."})
  end
end
