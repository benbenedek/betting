class AddFixturesInfo < ActiveRecord::Migration
  def change
    add_column :fixtures, :association_id, :integer
  end
end
