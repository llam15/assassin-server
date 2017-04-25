#!usr/bin/env ruby
require 'sinatra'
require "sinatra/activerecord"

# Centralize database config details in one place
set :database_file, 'database.yml'

get '/' do
  'Hello world'
end
