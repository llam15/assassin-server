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
      return nil
    end
  end

  def self.update_assignment(player_id, new_target_id)
    if ((TargetAssignment.exists?(player_id: player_id)) &&
       (TargetAssignment.exists?(player_id: new_target_id) || new_target_id == nil))

      player = TargetAssignment.find_by(player_id: player_id)
      player.update(target_id: new_target_id)
    else
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
      return nil
    end
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
        status 404
      end
    end

    # Receives {username: <username>}
    # Used for a user leaving the game
    # Will end game if game master leaves
    post '/game/leave' do
      parsed_request_body = JSON.parse(request.body.read)
      username = parsed_request_body['username']
      player = Player.find_by(username: username)
      if player
        # Leaving the game while the game is setting up
        if Game.first.status == "SettingUp"
          if player.role == "GameMaster"
            Game.first.destroy
            TargetAssignment.destroy_all
          else
            player.destroy
          end
        else
          # Leaving the game while game is in play
          player_hunter = Player.find_by(id: TargetAssignment.reverse_lookup_assignment(player.id))
          player_target = Player.find_by(id: TargetAssignment.lookup_assignment(player.id))
          TargetAssignment.update_assignment(player_hunter.id, player_target.id)

          # Change Game status if there is one person alive = end condition
          if player_target.id == player_hunter.id
            Game.first.update(status: 'Ended')
          end

          # Remove player from player's list and its TargetAssignments
          player.destroy
          TargetAssignment.where(player_id: player.id).destroy_all
        end
        status 200
      else
        status 404
      end
    end

    # Hunter has killed its target and takes a new target (victim's target)
    # Receives JSON in request body {hunter: <user1>, target: <user2>}
    post '/game/kill' do
      parsed_request_body = JSON.parse(request.body.read)
      hunter = Player.find_by(username: parsed_request_body['hunter'])
      target = Player.find_by(username: parsed_request_body['target'])


      # Validate kill claim
      # 1. distance < 3 meters
      # 2. target is hunter's assigned target
      hunter_location = [hunter.latitude, hunter.longitude]
      target_location = [target.latitude, target.longitude]
      distance = Geocoder::Calculations.distance_between(hunter_location, target_location)

      if distance < KILL_RADIUS && target.id == TargetAssignment.lookup_assignment(hunter.id)
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
        status 200
      else
        status 403
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


    # Expects: /game/hint?hunter=user1&target=user2
    get '/game/hint' do
      hunter = Player.find_by(username: params[:hunter])
      target = Player.find_by(username: params[:target])

      if hunter && target
        hunter_loc = [hunter.latitude, hunter.longitude]
        target_loc = [target.latitude, target.longitude]
        distance = Geocoder::Calculations.distance_between(hunter_loc, target_loc)

        # Convert to meters and approximate to 10 meters if rounding returns 0
        distance_in_meters = (distance * 1000).round(-1)
        if (distance_in_meters == 0)
          distance_in_meters = 10
        end

        return { distance: distance_in_meters }.to_json
      else
        status 404
      end
    end

    # Accepts { username: <username> }
    # Ends the game and resets all internal data if
    # the named player is the last one standing
    post '/game/end' do
      req = JSON.parse(request.body.read)
      username = req['username']

      player = Player.find_by(username: username)
      alive_players = Player.all.select { |player| player.alive }

      # Verify that this is the last player standing
      if player &&
         player.alive &&
         alive_players.size == 1 &&
         player.id == TargetAssignment.lookup_assignment(player.id)

        # While Games and Players are interdependent (we have
        # :destroy callbacks), TargetAssignment's have no
        # dependents and can be deleted as a row
        Game.destroy_all
        Player.destroy_all
        TargetAssignment.delete_all

        status 200
      else
        status 403
      end
    end

    # Allow direct execution of the app via 'ruby server.rb'
    run! if app_file == $0
  end
end
