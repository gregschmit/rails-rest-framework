class TestAppTables < ActiveRecord::Migration[6.0]
  def change
    create_table(:users) do |t|
      t.string(:login, null: false, default: "", index: {unique: true})
      t.boolean(:is_admin, default: false)
      t.integer(:age)
      t.decimal(:balance, precision: 8, scale: 2)
      t.integer(:state, null: false, default: 0)
      t.string(:status, null: false, default: "")

      t.references(:manager, foreign_key: {on_delete: :nullify, to_table: :users})

      t.timestamps(null: true)
    end

    create_table(:emails) do |t|
      t.string(:email, null: false, default: "", index: {unique: true})
      t.boolean(:is_primary, null: false, default: false)

      t.references(:user, null: true, foreign_key: {on_delete: :nullify})
    end

    add_reference(:users, :email, foreign_key: {on_delete: :nullify}, index: {unique: true})

    create_table(:phone_numbers) do |t|
      t.string(:number, null: false, default: "", index: {unique: true})

      t.references(:user, null: false, foreign_key: {on_delete: :cascade}, index: {unique: true})
    end

    create_table(:marbles) do |t|
      t.string(:name, null: false, default: "", index: {unique: true})
      t.integer(:radius_mm, null: false, default: 1)
      t.decimal(:price, precision: 6, scale: 2)
      t.boolean(:is_discounted, default: false)

      t.references(:user, foreign_key: {on_delete: :cascade})

      t.timestamps(null: true)
    end

    create_table(:genres) do |t|
      t.string(:name, null: false, default: "", index: {unique: true})
      t.string(:description, null: false, default: "")
    end

    create_table(:movies) do |t|
      t.string(:name, null: false, default: "", index: {unique: true})
      t.decimal(:price, precision: 8, scale: 2)

      t.references(:main_genre, foreign_key: {on_delete: :nullify, to_table: :genres})

      t.timestamps(null: true)
    end

    create_join_table(
      :movies, :genres, column_options: {null: false, foreign_key: {on_delete: :cascade}}
    ) do |t|
      t.index([:movie_id, :genre_id], unique: true)
    end

    create_join_table(
      :users, :movies, column_options: {null: false, foreign_key: {on_delete: :cascade}}
    ) do |t|
      t.index([:user_id, :movie_id], unique: true)
    end
  end
end
