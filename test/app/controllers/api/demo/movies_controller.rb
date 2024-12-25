class Api::Demo::MoviesController < Api::DemoController
  include RESTFramework::BulkModelControllerMixin

  self.extra_actions = {
    random: {
      methods: [:get], metadata: {description: "Get a random number.", method: "Dice roll."}
    },
  }

  def random
    puts "GNS: #{page_size}"
    self.page_size = 5
    puts "GNS: #{page_size}"
    return render_api({number: 4, message: "Chosen by fair dice roll. Guaranteed to be random."})
  end
end
