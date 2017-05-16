#!usr/bin/env ruby

# TODO: Move all models into a single folder
# TODO: Move server code into top-level app.rb,
#       and have a config/* for database config, etc.
#
# https://stackoverflow.com/questions/6766482/how-to-organize-models-in-sinatra

require "sinatra/base"
require "sinatra/activerecord"

# TODO: Move models into separate files
class Player < ActiveRecord::Base
  belongs_to :game
end

# TODO: Validate game status (ensure it follows the standard we set)
class Game < ActiveRecord::Base
  has_many :players, dependent: :destroy

  def players
    @players = Player.all.select { |player| player.game_id == self.id }
  end
end

class TargetAssignment < ActiveRecord::Base

  def self.add_new_assignment(player_id, target_id)
    TargetAssignment.create(player_id: player_id, target_id: target_id)
  end

  def self.lookup_assignment(player_id)
    if (TargetAssignment.exists?(player_id: player_id))
      player = TargetAssignment.find_by(player_id: player_id)
      player.target_id
    else
      puts "No target assignment for player with id #{player_id} exists"
      return nil
    end
  end

  def update_assignment(new_target_id)
    self.target_id = new_target_id
    self.save
  end
end

module Assassin
  VERSION = '0.1.0'

  class AssassinServer < Sinatra::Application
    # Centralize database config details in one place
    register Sinatra::ActiveRecordExtension
    set :database_file, 'database.yml'

    get '/hello_world' do
      'Hello world'
    end

    get '/game/players' do
      if Game.first
        Game.first.players.to_json
      else
        status 404
      end
    end

    get '/game' do
      if Game.first
        Game.first.to_json
      else
        status 404
      end
    end

    # Receives { username: <username> }
    post '/game/join' do
      parsed_request_body = JSON.parse(request.body.read)
      username = parsed_request_body['username']

      # While we have Game ID's, only have 1 game globally for now
      # If a game already exists, add player as a participant
      if Game.first
        participant = Player.new(username: username, role: 'Participant', alive: true)
        participant.game = Game.first
        participant.save
      else
        global_game = Game.create(status: 'SettingUp')
        game_master = Player.new(username: username, role: 'GameMaster', alive: true)
        game_master.game = global_game
        game_master.save
      end
    end

    # Expects /game/validate?username=[username]
    # Will determine if username is unique
    get '/game/validate' do
      username = params[:username]
      if Player.find_by(username: username)
        status 403
      else
        status 200
      end
    end

    post '/game/start' do
      if Game.first
        Game.first.update(status: 'InProgress')
      else
        puts "Game start called before game created"
        status 404
      end
    end

    # Receives {username: <username>}
    # Used for a user leaving the lobby
    # Will end game if game master leaves
    post '/game/leave' do
      parsed_request_body = JSON.parse(request.body.read)
      username = parsed_request_body['username']
      player = Player.find_by(username: username)
      if player
        if player.role == "GameMaster"
          puts "GameMaster leaving game! Delete global game object"
          Game.first.destroy
          TargetAssignment.delete_all
        else
          puts "A participant is leaving the lobby"
          player.destroy
        status 200
        end
      else
        puts "Player not in lobby"
        status 404
      end
    end

    # Allow direct execution of the app via 'ruby server.rb'
    run! if app_file == $0
  end
end
