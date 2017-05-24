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

  def self.lookup_assignment(player_id)
    if (TargetAssignment.exists?(player_id: player_id))
      player = TargetAssignment.find_by(player_id: player_id)
      player.target_id
    else
      puts "No target assignment for player with id #{player_id} exists"
      return nil
    end
  end
  
  def self.update_assignment(player_id, new_target_id)
    if ((TargetAssignment.exists?(player_id: player_id)) && 
        (TargetAssignment.exists?(player_id: new_target_id || new_target_id == nil)))
        
        player = TargetAssignment.find_by(player_id: player_id)
        player.update(target_id: new_target_id)
      else 
        puts "Id(s) are not valid"
        return nil
    end
  end
end

module Assassin
  VERSION = '0.1.0'

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
  
    # Hunter has killed its target and takes a new target (victim's target)
    # Receives JSON in request body {bodyhunter: <user1>, target: <user2>}
    post '/game/kill' do
      parsed_request_body = JSON.parse(request.body.read)
      hunter = Player.find_by(username: parsed_request_body['hunter'])
      target = Player.find_by(username: parsed_request_body['target'])
      
      # Assign new target to hunter & set victim's target to nil
      # If there is one player left, they will get assigned to themselves
      new_target_id = TargetAssignment.lookup_assignment(target.id)
      TargetAssignment.update_assignment(hunter.id, new_target_id)
      TargetAssignment.update_assignment(target.id, nil)
      
      # Mark victim as "dead" (= not alive)
      target.update(alive: false)
      
      # Change Game status if there is one person alive = end condition
      if new_target_id == hunter.id
        Game.first.update(status: 'Ended')
      end
    end
    
    # Expects /game/target?username=[username]
    # Will determine the username's target
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

    # Receives {username: <username>; latitude: <latitude>; longitude: <longitude>}
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
          player.latitude = latitude
          player.longitude = longitude
          player.save
          status 200
        else
          status 404
        end
      end
    end

    # Allow direct execution of the app via 'ruby server.rb'
    run! if app_file == $0
  end
end
