class AddOneIdToTeams < ActiveRecord::Migration[7.0]
    def change
      add_column :teams, :one_id, :integer
      add_index :teams, :one_id
    end
end
