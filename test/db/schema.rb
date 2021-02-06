ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :login
    t.boolean :is_admin, default: false
    t.integer :age
    t.decimal :balance, precision: 8, scale: 2

    t.timestamps null: true
  end

  create_table :things, force: true do |t|
    t.string :name
    t.string :shape
    t.decimal :price, precision: 6, scale: 2
    t.boolean :is_discounted, default: false
    t.references :owner, index: true, foreign_key: { to_table: :users, on_delete: :cascade }

    t.timestamps null: true
  end
end
