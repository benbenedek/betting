class AddFixtureBetIdToUserBet < ActiveRecord::Migration
  def change
    add_column :user_bets, :fixture_bet_id, :integer
  end
end
