Game.create({status: 'InProgress'})

gm = Player.new(username: 'gm', role: 'GameMaster', alive: true)
gm.game = Game.first
gm.save

participant_1 = Player.new(username: 'kycuong', role: 'Participant', alive: true)
participant_1.game = Game.first
participant_1.save

participant_2 = Player.new(username: 'bnery', role: 'Participant', alive: true)
participant_2.game = Game.first
participant_2.save

participant_3 = Player.new(username: 'meeshic', role: 'Participant', alive: true)
participant_3.game = Game.first
participant_3.save

TargetAssignment.add_new_assignment(1,2)
TargetAssignment.add_new_assignment(2,3)
TargetAssignment.add_new_assignment(3,4)
TargetAssignment.add_new_assignment(4,1)

Player.find_by(username: "gm").update(latitude: 44.981677, longitude:  -93.27833)
Player.find_by(username: "kycuong").update(latitude: 44.981867, longitude:  -93.27833)
Player.find_by(username: "bnery").update(latitude: 44.981669, longitude:  -93.27833)
Player.find_by(username: "meeshic").update(latitude: 44.981672, longitude:  -93.27833)