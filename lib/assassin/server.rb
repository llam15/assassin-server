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
      Game.first.players.to_json
    end

    # Receives { username: <username> }
    post '/game/create' do
      parsed_request_body = JSON.parse (request.body.read)
      username = parsed_request_body['username']

      # While we have Game ID's, only have 1 game globally for now
      unless Game.first.nil?
        'A global game already exists'
      else
        global_game = Game.create(status: 'SettingUp')
        game_master = Player.new(username: username, role: 'GameMaster', alive: true)
        game_master.game = @global_game
        game_master.save
      end
    end

    # Allow direct execution of the app via 'ruby server.rb'
    run! if app_file == $0
  end
end
