# Basic Rake tutorial: http://lukaszwrobel.pl/blog/rake-tutoria
# List all available tasks via: "bundle exec rake -T"
require 'sinatra/activerecord/rake'

# 'namespace' gives us tasks like: "rake db:do_this, rake db:do_that  "
namespace :db do
  task :load_config do
    require './assassin-server.rb'
  end
end

task :test do
  puts 'Test!'
end

task :default => :test
