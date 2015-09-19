class AddFixtureIdToMatches < ActiveRecord::Migration
  def change
    add_column :matches, :fixture_id, :integer
  end
end
