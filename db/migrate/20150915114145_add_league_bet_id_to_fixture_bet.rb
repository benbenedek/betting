class AddLeagueBetIdToFixtureBet < ActiveRecord::Migration
  def change
    add_column :fixture_bets, :league_bet_id, :integer
  end
end
