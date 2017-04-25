# List all available tasks via: "bundle exec rake -T"
require "rake/testtask"
require 'sinatra/activerecord/rake'

namespace :db do
  task :load_config do
    require './assassin-server.rb'
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test
