# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_01_11_070115) do
  create_table "movies", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.decimal "price", precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_movies_on_name", unique: true
  end

  create_table "movies_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "movie_id", null: false
    t.index ["user_id", "movie_id"], name: "index_movies_users_on_user_id_and_movie_id", unique: true
  end

  create_table "things", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "shape"
    t.decimal "price", precision: 6, scale: 2
    t.boolean "is_discounted", default: false
    t.integer "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_things_on_name", unique: true
    t.index ["owner_id"], name: "index_things_on_owner_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "login", default: "", null: false
    t.boolean "is_admin", default: false
    t.integer "age"
    t.decimal "balance", precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["login"], name: "index_users_on_login", unique: true
  end

  add_foreign_key "movies_users", "movies", on_delete: :cascade
  add_foreign_key "movies_users", "users", on_delete: :cascade
  add_foreign_key "things", "users", column: "owner_id", on_delete: :cascade
end
