class CreateTargetAssignments < ActiveRecord::Migration[5.0]
  def change
    create_table :target_assignments do |t|
      t.integer :player_id
      t.integer :target_id
    end
  end
end
