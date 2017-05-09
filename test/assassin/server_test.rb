require 'test_helper'

class Assassin::ServerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Assassin::AssassinServer
  end

  def test_that_it_has_a_version_number
    refute_nil Assassin::VERSION
  end

  # Integration Tests
  def test_hello_world
    get '/hello_world'
    assert last_response.ok?
    assert_equal 'Hello world', last_response.body
  end

  # TODO: should not be able to save a Player w/o an associated game
end
