# Seed data is used for controller tests which need data to be useful, and also for the Demo API.

User.create!(
  login: "example",
  age: 23,
  balance: 20.34,
  things_attributes: [
    {name: "Example Thing 1", shape: "Square", price: 4},
    {name: "Example Thing 2", shape: "Hexagon", price: 8},
  ],
)
User.create!(
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
