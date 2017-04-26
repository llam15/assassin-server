# To start AssassinServer: rackup -p 4567
# To watch for changes and automatically restart, run:
# rerun "rackup -p 4567"

require './lib/assassin/server'
run Assassin::AssassinServer
