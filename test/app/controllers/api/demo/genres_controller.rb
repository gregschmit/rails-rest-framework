class Api::Demo::GenresController < Api::DemoController
  self.model = Genre
  self.bulk = :raw
end
