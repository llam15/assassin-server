class CreateGames < ActiveRecord::Migration[5.0]
  def change
    create_table :games do |t|
      t.string :status # WaitingForPlayers, Started, or Ended
    end
  end
end
