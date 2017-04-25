# frozen_string_literal: true
source 'https://rubygems.org'

gem 'sinatra', '~> 1.4.7'  # Our chosen web app framework
gem "sinatra-activerecord", '2.0.13' # Our chosen ORM for any SQL database
gem 'thin',    '~> 1.7.0'  # Basic web server
gem 'rerun',   '~> 0.11.0' # Out-of-process reloader for Ruby apps
gem 'rake',    '~> 12.0.0' # Make-like build tool, but easier-to-use

group :development, :test do
  gem 'sqlite3', '1.3.13'   # Avoid upgrading database version without testing
end

group :test do
  gem 'minitest', '~>5.10.1' # Our chosen testing framework
end

