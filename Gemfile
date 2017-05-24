# frozen_string_literal: true
source 'https://rubygems.org'
ruby '2.4.0'

gem 'sinatra', '~> 1.4.7'  # Our chosen web app framework
gem "sinatra-activerecord", '2.0.13' # Our chosen ORM for any SQL database
gem 'thin',     '~> 1.7.0'  # Basic web server
gem 'rerun',    '~> 0.11.0' # Out-of-process reloader for Ruby apps
gem 'rake',     '~> 12.0.0' # Make-like build tool, but easier-to-use
gem 'rack',     '~> 1.6.5'  # HTTP handling
gem 'json',     '~> 2.1.0'  # JSON handling
gem 'pg',       '0.20.0'    # Avoid upgrading database version without testing
gem 'geocoder', '~>1.4.4'   # GPS coordinate and location handling

group :development, :test do
  gem 'pry',            '~> 0.10.4'   # Ruby debugger
  gem 'pry-byebug',     '~> 3.4.2'    # Get continue/next/step/etc. debugging commands
  gem 'awesome_print',  '~> 1.7.0'    # Pretty-print anything
  gem 'tux',           '~> 0.3.0'  # App console
end

group :test do
  gem 'minitest', '~> 5.10.1' # Our chosen testing framework
  gem 'minitest-reporters', '~> 1.1.14' # Adds color to test output
  gem 'rack-test', '~> 0.6.3' # Integration test framework
end

