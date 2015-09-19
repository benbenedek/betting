class CreateFixtures < ActiveRecord::Migration
  def change
    create_table :fixtures do |t|
      t.integer :number
      t.date :date

      t.timestamps null: false
    end
  end
end
