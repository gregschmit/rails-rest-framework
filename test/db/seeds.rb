# Seed data is used for the Demo API as well as initial test data in lieu of fixtures.

require "base64"
require "stringio"

# Always clear the database before seeding.
puts "Clearing database..."
Star.delete_all
Email.delete_all
Genre.delete_all
Movie.delete_all
PhoneNumber.delete_all
User.delete_all

# `Movie.delete_all` skips callbacks, so the Action Text and Active Storage rows it owns aren't
# removed; purge them here so re-seeding stays idempotent.
ActiveStorage::Attachment.find_each(&:purge)
ActionText::RichText.delete_all

SEED = 42
Faker::Config.random = Random.new(SEED)
srand(SEED)

puts "Seed data loading..."

example = User.create!(
  login: "example",
  age: 23,
  balance: 20.34,
  state: "pending",
  status: "online",
)
admin = User.create!(
  login: "admin",
  is_admin: true,
  age: 34,
  balance: 230.34,
)
example.update!(manager: admin)

1000.times do |_|
  legal_name = Faker::Name.name_with_middle
  short_name = legal_name.gsub(/^[a-zA-Z]*\./, "").split(" ").first
  login = Faker::Internet.username(specifier: legal_name) + rand(1..100).to_s

  # Generate either 0, 1, or 2 emails:
  emails = [ 0, *([ 1 ] * 8), 2 ].sample.times.map do |i|
    Email.create!(email: Faker::Internet.email(name: legal_name), is_primary: i == 0)
  end

  u = User.create!(
    login: login,
    legal_name: legal_name,
    short_name: short_name,
    age: rand(18..65),
    is_admin: rand < 0.2,
    balance: rand(0.0..10000.0),
    state: [ 0, 0, 0, 0, User.states.keys.sample ].sample,
    status: User::STATUS_OPTS.keys.sample,
    day_start: [ "7:30", "8:00", "8:30", "9:00", "9:30" ].sample,
    last_reviewed_on: Time.zone.today - rand(0..365).days,
    manager: [ nil, nil, nil, example, admin, User.first(10).sample ].sample,
    billing_email: rand < 0.5 ? emails.first : nil,
    emails: emails,
  )

  # Triggers stack error on users controller somehow.
  if rand < 0.7
    PhoneNumber.create!(number: Faker::PhoneNumber.cell_phone, user: u)
  end
rescue ActiveRecord::RecordInvalid
end

# Created by copilot:
Genre.create!(name: "Action", description: "Action movies are fast-paced and exciting.")
Genre.create!(name: "Comedy", description: "Comedy movies are funny.")
Genre.create!(name: "Drama", description: "Drama movies are serious.")
Genre.create!(name: "Fantasy", description: "Fantasy movies are magical.")
Genre.create!(name: "Adventure", description: "Adventure movies are exciting.")
Genre.create!(name: "Sci-Fi", description: "Sci-Fi movies are futuristic.")
Genre.create!(name: "Horror", description: "Horror movies are scary.")
Genre.create!(name: "Thriller", description: "Thriller movies are suspenseful.")
Genre.create!(name: "Mystery", description: "Mystery movies are puzzling.")
Genre.create!(name: "Romance", description: "Romance movies are about love.")
Genre.create!(name: "Musical", description: "Musical movies have singing and dancing.")
Genre.create!(name: "Documentary", description: "Documentary movies are non-fiction.")
Genre.create!(name: "Animation", description: "Animation movies are animated.")
Genre.create!(name: "Family", description: "Family movies are for all ages.")
Genre.create!(name: "Western", description: "Western movies are about the American West.")
Genre.create!(name: "War", description: "War movies are about military conflict.")
Genre.create!(name: "History", description: "History movies are about the past.")
Genre.create!(name: "Biography", description: "Biography movies are about real people.")
Genre.create!(name: "Sport", description: "Sport movies are about athletics.")
Genre.create!(name: "Music", description: "Music movies are about musicians.")
Genre.create!(name: "Crime", description: "Crime movies are about criminals.")
Genre.create!(name: "Noir", description: "Noir movies are dark and cynical.")
Genre.create!(name: "Superhero", description: "Superhero movies are about heroes.")
Genre.create!(name: "Spy", description: "Spy movies are about espionage.")

all_genres = Genre.all.to_a

# Tiny 10x10 solid-color PNGs, used as placeholder movie images.
# rubocop:disable Layout/LineLength
sample_images = {
  "red.png" => "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC",
  "green.png" => "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9Qz0AEYBxVSF+FAAhKDveksOjmAAAAAElFTkSuQmCC",
  "blue.png" => "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNkYPhfz0AEYBxVSF+FAP5FDvcfRYWgAAAAAElFTkSuQmCC",
}.transform_values { |data| Base64.decode64(data) }
# rubocop:enable Layout/LineLength

50.times do
  movie = Movie.create!(
    name: Faker::Movie.title,
    price: rand(5.0..20.0),
    main_genre: all_genres.sample,
    description: "<p>#{Faker::Lorem.paragraph(sentence_count: 2)}</p>",
  )

  # Genres (a HABTM, distinct from the single `main_genre`).
  movie.genres = all_genres.sample(rand(1..3))

  # Attach a cover to every movie, and a handful of pictures to some.
  cover_name, cover_data = sample_images.to_a.sample
  movie.cover.attach(
    io: StringIO.new(cover_data), filename: cover_name, content_type: "image/png",
  )
  if rand < 0.4
    sample_images.to_a.sample(rand(1..3)).each do |name, data|
      movie.pictures.attach(io: StringIO.new(data), filename: name, content_type: "image/png")
    end
  end
rescue ActiveRecord::RecordInvalid
end

example.movies += Movie.all.sample(5)
admin.movies += Movie.all.sample(20)

# Assign polymorphic favorites (a Movie or a Genre) to demonstrate how the framework serializes
# polymorphic references.
favorites = Movie.all.to_a + Genre.all.to_a
example.update!(favorite: Movie.first)
admin.update!(favorite: Genre.first)
User.where(favorite_id: nil).limit(200).find_each do |u|
  u.update!(favorite: favorites.sample)
end

# "Star" a mix of movies and genres for a couple of users, via the polymorphic join model.
[ example, admin ].each do |u|
  favorites.sample(5).each { |starrable| Star.create!(user: u, starrable: starrable) }
end

puts "Seed data loaded."
