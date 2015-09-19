class CreateLeagueBets < ActiveRecord::Migration
  def change
    create_table :league_bets do |t|
      t.references :league, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
