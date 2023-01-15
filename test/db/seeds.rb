# Seed data is used for controller tests which need data to be useful, and also for the Demo API.

example = User.create!(
  login: "example",
  age: 23,
  balance: 20.34,
  state: "pending",
  status: "online",
  things_attributes: [
    {name: "Example Thing 1", shape: "Square", price: 4},
    {name: "Example Thing 2", shape: "Hexagon", price: 8},
  ],
)
admin = User.create!(
  login: "admin",
  is_admin: true,
  age: 34,
  balance: 230.34,
  things_attributes: [
    {name: "Admin Thing 1", shape: "Circle", price: 9.23},
    {name: "Admin Thing 2", shape: "Triangle", price: 149.23},
  ],
)

Thing.create!(name: "Orphan Thing 1", shape: "Mobius Strip", price: 4000)
Thing.create!(name: "Orphan Thing 2", shape: "Umbilic Torus", price: 5000)

star_wars = Movie.create!(name: "Star Wars IV: A New Hope", price: 14.99)
dark_knight = Movie.create!(name: "The Dark Knight", price: 13.99)
fellowship = Movie.create!(name: "The Lord of the Rings: The Fellowship of the Ring", price: 12.99)
matrix = Movie.create!(name: "The Matrix", price: 14.50)
_avengers = Movie.create!(name: "The Avengers", price: 7.00)
_inception = Movie.create!(name: "Inception", price: 15.99)

example.movies += [star_wars, dark_knight]
admin.movies += [star_wars, fellowship, matrix]
