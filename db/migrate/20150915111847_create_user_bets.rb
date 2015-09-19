class CreateUserBets < ActiveRecord::Migration
  def change
    create_table :user_bets do |t|
      t.references :user, index: true, foreign_key: true
      t.references :bet, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
