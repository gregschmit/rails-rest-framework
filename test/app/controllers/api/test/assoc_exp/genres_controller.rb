# The sibling for `Movie#main_genre`. It serializes through a custom serializer, so the framework
# can't introspect what it exposes and must refuse to derive an allowlist from it.
class Api::Test::AssocExp::GenresController < Api::TestController
  self.model = Genre

  class GenreSerializer < RESTFramework::NativeSerializer
    self.config = { only: [ :id, :name ] }
  end

  self.serializer_class = GenreSerializer
end
