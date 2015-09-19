class AddLeagueIdToFixtures < ActiveRecord::Migration
  def change
    add_column :fixtures, :league_id, :integer
  end
end
