#!usr/bin/env ruby
require "sinatra/base"
require "sinatra/activerecord"
require "pry"
require "../../db/models/player.rb"
module Assassin
  VERSION = "0.1.0"

  class AssassinServer < Sinatra::Application
    register Sinatra::ActiveRecordExtension
    # Centralize database config details in one place
    # TODO: Either inside our outside the class, will test
    set :database_file, 'database.yml'

    get '/hello_world' do
      'Hello world'
    end

    Pry.start
    run! if app_file == $0

  end
end