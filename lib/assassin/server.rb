#!usr/bin/env ruby

# TODO: Move all models into a single folder
# TODO: Move server code into top-level app.rb,
#       and have a config/* for database config, etc.
#
# https://stackoverflow.com/questions/6766482/how-to-organize-models-in-sinatra

require "sinatra/base"
require "sinatra/activerecord"

class Player < ActiveRecord::Base
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
      Player.all.to_json
    end

    # Allow direct execution of the app via 'ruby server.rb'
    run! if app_file == $0
  end
end
