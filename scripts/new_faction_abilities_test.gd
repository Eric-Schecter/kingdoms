extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.army_factions=[2,1]
 game.new_battle()
 game.animation_speed=100
 for u in game.units: u.total=0
 for id in [8,4]: game.units[id].total=game.units[id].max_total
 game.units[8].pos=Vector2i(6,4)
 game.units[4].pos=Vector2i(7,4)
 var before=game.speed(game.units[4])
 await game.perform_attack(8,4,false)
 assert(game.units[4].rooted and game.speed(game.units[4])==0)
 game.queue_free()
 await process_frame
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.army_factions=[4,0]
 game.new_battle()
 game.animation_speed=100
 for u in game.units: u.total=0
 for id in [9,4]: game.units[id].total=game.units[id].max_total
 game.units[9].pos=Vector2i(6,4)
 game.units[4].pos=Vector2i(7,4)
 before=game.units[4].total
 await game.perform_attack(4,9,false,true)
 assert(game.units[4].total<before,"Fire shield reflects melee damage even on retaliation")
 game.units[10].total=game.units[10].max_total
 game.units[10].pos=Vector2i(6,4)
 game.units[4].total=game.units[4].max_total
 game.units[4].retaliated=false
 await game.perform_attack(10,4,false)
 assert(not game.units[4].retaliated,"Devil suppresses retaliation")
 print("NEW ABILITIES PASS: binding immobilization, fire shield, devil no retaliation")
 quit()
