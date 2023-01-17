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

ActiveRecord::Schema[7.0].define(version: 2023_01_15_233930) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "marbles", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.integer "radius_mm", default: 1, null: false
    t.decimal "price", precision: 6, scale: 2
    t.boolean "is_discounted", default: false
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_marbles_on_name", unique: true
    t.index ["user_id"], name: "index_marbles_on_user_id"
  end

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

  create_table "users", force: :cascade do |t|
    t.string "login", default: "", null: false
    t.boolean "is_admin", default: false
    t.integer "age"
    t.decimal "balance", precision: 8, scale: 2
    t.integer "state", default: 0, null: false
    t.string "status", default: "", null: false
    t.integer "manager_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["login"], name: "index_users_on_login", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "marbles", "users", on_delete: :cascade
  add_foreign_key "movies_users", "movies", on_delete: :cascade
  add_foreign_key "movies_users", "users", on_delete: :cascade
  add_foreign_key "users", "users", column: "manager_id", on_delete: :nullify
end
