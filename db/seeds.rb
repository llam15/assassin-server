Game.create({status: 'SettingUp'})

gm = Player.new(username: 'gm', role: 'GameMaster', alive: true)
gm.game = Game.first
gm.save

participant_1 = Player.new(username: 'player_1', role: 'Participant', alive: true)
participant_1.game = Game.first
participant_1.save

participant_2 = Player.new(username: 'player_2', role: 'Participant', alive: true)
participant_2.game = Game.first
participant_2.save

participant_3 = Player.new(username: 'player_3', role: 'Participant', alive: true)
participant_3.game = Game.first
participant_3.save

TargetAssignment.add_new_assignment(1,2)
TargetAssignment.add_new_assignment(2,3)
TargetAssignment.add_new_assignment(3,1)