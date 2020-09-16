ActiveRecord::Schema.define do
  create_table :things, force: true do |t|
    t.string :name
    t.integer :amount
    t.boolean :is_cool, default: false

    t.timestamps
  end
end
