# Seed data is used for controller tests which need data to be useful, and also for the Demo API.

example = User.create!(
  login: "example",
  age: 23,
  balance: 20.34,
  state: "pending",
  status: "online",
  marbles_attributes: [
    {name: "Example Marble 1", radius_mm: 10, price: 4},
    {name: "Example Marble 2", radius_mm: 8, price: 8},
  ],
)
admin = User.create!(
  login: "admin",
  is_admin: true,
  age: 34,
  balance: 230.34,
  marbles_attributes: [
    {name: "Admin Marble 1", radius_mm: 11, price: 9.23},
    {name: "Admin Marble 2", radius_mm: 20, price: 149.23},
  ],
)

Marble.create!(name: "Orphan Marble 1", radius_mm: 300, price: 4000)
Marble.create!(name: "Orphan Marble 2", radius_mm: 314, price: 5000)

action = Genre.create!(name: "Action", description: "Action movies are fast-paced and exciting.")
_comedy = Genre.create!(name: "Comedy", description: "Comedy movies are funny.")
_drama = Genre.create!(name: "Drama", description: "Drama movies are serious.")
fantasy = Genre.create!(name: "Fantasy", description: "Fantasy movies are magical.")
adventure = Genre.create!(name: "Adventure", description: "Adventure movies are exciting.")

star_wars = Movie.create!(name: "Star Wars IV: A New Hope", price: 14.99, main_genre: action)
dark_knight = Movie.create!(name: "The Dark Knight", price: 13.99, main_genre: action)
fellowship = Movie.create!(
  name: "The Lord of the Rings: The Fellowship of the Ring", price: 12.99, main_genre: adventure,
)
matrix = Movie.create!(name: "The Matrix", price: 14.50, main_genre: action)
_avengers = Movie.create!(name: "The Avengers", price: 7.00, main_genre: action)
_inception = Movie.create!(name: "Inception", price: 15.99, main_genre: fantasy)

example.movies += [star_wars, dark_knight]
admin.movies += [star_wars, fellowship, matrix]
