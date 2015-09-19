class CreateBets < ActiveRecord::Migration
  def change
    create_table :bets do |t|
      t.string :prediction
      t.references :match, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
