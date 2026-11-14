extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var game=load("res://main.tscn").instantiate()
	game.choosing_faction=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	assert(game.units.size()==14,"Expected fourteen creature types")
	assert(game.current==10,"Angels should act first")
	assert(game.neighbors(Vector2i(7,5)).size()==6)
	assert(game.neighbors(Vector2i(0,0)).size()==2)
	assert(game.amount(game.units[0])==50)
	game.units[0].total=game.units[0].hp+1
	assert(game.amount(game.units[0])==2,"Wounded creature stays in the stack")
	game.units[0].total=500
	# Ground troops cannot enter obstacles; flying units can cross them.
	game.units[0].pos=Vector2i(5,3)
	var ground=game.paths(0)
	assert(not ground.has(Vector2i(6,3)))
	game.units[3].pos=Vector2i(5,3)
	var flying=game.paths(3)
	assert(flying.has(Vector2i(8,3)),"Griffin must cross rocks")
	game.units[0].pos=Vector2i(1,1)
	game.units[3].pos=Vector2i(1,9)
	assert(game.can_shoot(1))
	game.units[4].pos=Vector2i(1,2)
	assert(not game.can_shoot(1),"Adjacent enemy blocks shooting")
	game.units[4].pos=Vector2i(13,1)
	# Defending reduces incoming damage.
	var before=game.damage_range(game.units[4],game.units[0],false)
	game.units[0].guard=true
	var after=game.damage_range(game.units[4],game.units[0],false)
	assert(after.x<=before.x and after.y<before.y)
	game.units[0].guard=false
	var active=game.current
	assert(not game.has_method("cast_spell"))
	# Retaliation is spent once; a retaliatory blow does not recurse.
	game.units[0].total=500
	game.units[4].total=390
	game.units[4].retaliated=false
	game.units[0].pos=Vector2i(6,4)
	game.units[4].pos=Vector2i(7,4)
	game.units[0].visual=game.unit_center(0)
	game.units[4].visual=game.unit_center(4)
	var attacker_hp=game.units[0].total
	await game.perform_attack(0,4,false)
	assert(game.units[4].retaliated)
	assert(game.units[0].total<attacker_hp)
	attacker_hp=game.units[0].total
	await game.perform_attack(0,4,false)
	assert(game.units[0].total==attacker_hp)
	game.wait_action()
	assert(game.waiting.has(active),"Waiting stack returns in the second phase")
	print("RULES_TEST PASS: hex adjacency, stacks, obstacles, flight, shooting lock, defense, no hero casting, retaliation, waiting")
	quit()
