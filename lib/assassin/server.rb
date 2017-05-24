#!usr/bin/env ruby

# TODO: Move all models into a single folder
# TODO: Move server code into top-level app.rb,
#       and have a config/* for database config, etc.
#
# https://stackoverflow.com/questions/6766482/how-to-organize-models-in-sinatra

require 'sinatra/base'
require 'sinatra/activerecord'
require 'geocoder'

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

  # Find the target for a given player
  # Returns the target's ID
  def self.lookup_assignment(player_id)
    if TargetAssignment.exists?(player_id: player_id)
      player = TargetAssignment.find_by(player_id: player_id)
      player.target_id
    else
      puts "No target assignment for player with id #{player_id} exists"
      return nil
    end
  end

  # Find the hunter of a given player
  # Returns the hunter's ID
  def self.reverse_lookup_assignment(player_id)
    if TargetAssignment.exists?(player_id: player_id)
      hunter = TargetAssignment.find_by(target_id: player_id)
      hunter.player_id
    else
      puts "No hunter for player wtih id #{player_id} exists"
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
  KILL_RADIUS = 0.003 # kilometers, i.e., 3 meters

  class AssassinServer < Sinatra::Application
    # Centralize database config details in one place
    register Sinatra::ActiveRecordExtension
    set :database_file, 'database.yml'
    # Use kilometers for our calculations for easier conversion
    Geocoder.configure(units: :km)

    get '/hello_world' do
      'Hello world'
    end

    get '/game' do
      if Game.first
        Game.first.to_json
      else
        status 404
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

    get '/game/players' do
      if Game.first
        Game.first.players.to_json
      else
        status 404
      end
    end

    post '/game/start' do
      global_game = Game.first
      # Multiple target assignments are avoided by
      # dumping all assignments between games
      if global_game
        if global_game.status == 'InProgress'
          puts "Game has already begun and is in progress"
          status 403
        else
          global_game.update(status: 'InProgress')
          shuffled_players = global_game.players.shuffle

          # Circular, singly-linked list target assignment
          shuffled_players.each_with_index do |player, index|
            # Special case: last player -> first player
            if index == shuffled_players.size - 1
              TargetAssignment.add_new_assignment(
                player.id, shuffled_players[0].id
              )
            else
              TargetAssignment.add_new_assignment(
                player.id, shuffled_players[index + 1].id
              )
            end
          end
          status 200
        end
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
        end
      status 200
      else
        puts "Player not in lobby"
        status 404
      end
    end

    # Expects /game/target?username=[username]
    # Will return the Player's target
    get '/game/target' do
      username = params[:username]
      player = Player.find_by(username: username)
      if player
        target_id = TargetAssignment.lookup_assignment(player.id)
        if target_id
          target_username = Player.find_by(id: target_id).username
          return { target: target_username }.to_json
        else # Target_id is nil
          return { target: "" }.to_json
        end
        status 200
      else
        status 404
      end
    end

    # Receives { "username": <username>; "latitude": <latitude>; "longitude": <longitude> }
    # Responds with { "ready_for_kill": true/false, "in_danger": true/false, "alive": true/false }
    # We thus update their world awareness as hunter/hunted, and their current alive/dead status
    post '/game/location' do
      req = JSON.parse(request.body.read)
      username = req['username']
      latitude = req['latitude']
      longitude = req['longitude']

      if latitude == nil || longitude == nil
        status 403
      else
        player = Player.find_by(username: username)
        if player
          player.update(latitude: latitude, longitude: longitude)
          player_location = [player.latitude, player.longitude]

          target = Player.find_by(id: TargetAssignment.lookup_assignment(player.id))
          target_location = [target.latitude, target.longitude] if target

          hunter = Player.find_by(id: TargetAssignment.reverse_lookup_assignment(player.id))
          hunter_location = [hunter.latitude, hunter.longitude] if hunter

          # Are we close enough to kill our target?
          ready_for_kill = Geocoder::Calculations.distance_between(player_location, target_location) < KILL_RADIUS
          # Is our hunter close enough to kill us?
          in_danger = Geocoder::Calculations.distance_between(player_location, hunter_location) < KILL_RADIUS

          status 200
          return { ready_for_kill: ready_for_kill,
                   in_danger: in_danger,
                   alive: player.alive
                 }.to_json
        else
          status 404
          return {}
        end
      end
    end

    # Allow direct execution of the app via 'ruby server.rb'
    run! if app_file == $0
  end
end
