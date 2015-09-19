class AddUserBetIdToBets < ActiveRecord::Migration
  def change
    add_column :bets, :user_bet_id, :integer
  end
end
