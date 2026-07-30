# Parent for the custom-serializer-sibling case: `main_genre`'s sibling
# (`Api::Test::AssocExp::GenresController`) uses a custom serializer, so expansion must fall back to
# the defaults rather than trusting the sibling's `get_fields`.
class Api::Test::AssocExp::MoviesController < Api::TestController
  self.model = Movie
  self.fields = %w[id name main_genre]
  self.enable_association_queries = true
end
