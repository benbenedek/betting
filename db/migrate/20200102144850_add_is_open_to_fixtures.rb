class AddIsOpenToFixtures < ActiveRecord::Migration
  def change
    add_column :fixtures, :is_open, :boolean
  end
end
