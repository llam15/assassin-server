class CreatePlayers < ActiveRecord::Migration[5.0]
  def change
    create_table :players do |t|
      t.string    :username
      t.string    :role # Game Master or Participant
      t.boolean   :alive
      t.float     :latitude
      t.float     :longitude
    end
  end
end
