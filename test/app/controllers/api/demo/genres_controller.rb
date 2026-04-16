class Api::Demo::GenresController < Api::DemoController
  self.model = Genre
  self.bulk = true
end
