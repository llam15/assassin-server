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
  has_many :players

  def players
    @players = Player.all.select { |player| player.game_id == self.id }
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

    # Allow direct execution of the app via 'ruby server.rb'
    run! if app_file == $0
  end
end
