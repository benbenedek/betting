class AddLeagueAndGameInfo < ActiveRecord::Migration
  def change
    add_column :teams, :association_id, :integer
    add_column :leagues, :association_id, :integer
    add_column :matches, :association_id, :integer
  end
end
