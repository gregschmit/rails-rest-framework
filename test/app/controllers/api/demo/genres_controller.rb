class Api::Demo::GenresController < Api::DemoController
  self.model = Genre
  self.bulk = :raw

  # Opt this one controller out of the propagated `ping` action (a local removal).
  remove_action(:ping)
end
