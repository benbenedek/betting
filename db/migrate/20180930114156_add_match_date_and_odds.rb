class AddMatchDateAndOdds < ActiveRecord::Migration
  def change
    add_column :matches, :date, :timestamp
    add_column :matches, :home_odds, :float
    add_column :matches, :away_odds, :float
  end
end
