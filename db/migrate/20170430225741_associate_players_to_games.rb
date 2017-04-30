class AssociatePlayersToGames < ActiveRecord::Migration[5.0]
  def change
    change_table :players do |t|
      t.belongs_to :game, index: true
    end 
  end
end
