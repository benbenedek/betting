class CreateFixtureBets < ActiveRecord::Migration
  def change
    create_table :fixture_bets do |t|
      t.references :fixture, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
