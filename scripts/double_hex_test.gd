extends SceneTree
var game
var checks=0

func expect(value: bool, message: String):
	checks+=1
	if not value:
		push_error(message)
		quit(1)
		assert(value,message)

func place(id: int, head: Vector2i, facing: int=0):
	game.units[id].pos=head
	if facing!=0: game.units[id].facing=facing
	game.units[id].visual=game.unit_center(id)

func _initialize(): call_deferred("run")

func run():
	game=load("res://main.tscn").instantiate()
	game.choosing_faction=false
	root.add_child(game)
	await process_frame
	game.animation_speed=8.0
	game.self_test=false
	game.busy=true
	expect(game.validate_layout(),"Initial deployment must be valid")
	expect(game.footprint(3)==[Vector2i(1,5),Vector2i(0,5)],"Griffin takes two hexes")
	expect(game.footprint(7)==[Vector2i(13,5),Vector2i(14,5)],"Enemy horse faces left")
	expect(game.occupant(Vector2i(0,5))==3,"Tail selects the same creature")
	expect(game.occupant(Vector2i(14,5))==7,"Horse tail is occupied")
	expect(not game.can_place(3,Vector2i(0,4),1),"Tail cannot leave left edge")
	expect(not game.can_place(7,Vector2i(14,4),-1),"Tail cannot leave right edge")
	expect(not game.can_place(3,Vector2i(8,3),1),"Tail cannot land on a rock")
	expect(not game.can_place(3,Vector2i(2,3),1),"Tail cannot land on an ally")
	var before=game.footprint(7)
	var center=game.unit_center(7)
	await game.turn_unit(7,1)
	var after=game.footprint(7)
	expect(after.has(before[0]) and after.has(before[1]),"Turn keeps the same two hexes")
	expect(game.units[7].pos==Vector2i(14,5),"Turn swaps head with tail")
	expect(game.unit_center(7).is_equal_approx(center),"Turn must not slide the body")
	await game.turn_unit(7,-1)
	# A two-hex ground creature cannot pass a one-hex opening in a full wall.
	var original_obstacles=game.obstacles.duplicate()
	game.obstacles.clear()
	for x in range(game.COLS):
		if x!=7: game.obstacles.append(Vector2i(x,5))
	place(7,Vector2i(7,3),-1)
	var horse_paths=game.paths(7,true)
	var crossed=false
	for p in horse_paths:
		if p.y>5: crossed=true
	expect(not crossed,"Horse must not squeeze through a one-hex corridor")
	place(3,Vector2i(7,3),1)
	var griffin_paths=game.paths(3,true)
	expect(griffin_paths.has(Vector2i(7,7)),"Flying creature can cross the wall")
	for p in griffin_paths:
		for option in griffin_paths[p].options:
			expect(game.can_place(3,p,option.facing),"Every highlighted flying landing fits both cells")
	game.obstacles.assign(original_obstacles)
	place(7,Vector2i(13,5),-1)
	place(3,Vector2i(1,5),1)
	# Adjacency at the tail participates in melee and suppresses archery.
	place(7,Vector2i(5,4),1)
	place(1,Vector2i(3,4))
	expect(game.touches(1,7,game.units[1].pos),"Melee can contact the rear half")
	expect(not game.can_shoot(1),"A horse tail blocks ranged shooting")
	game.reachable=game.paths(1)
	expect(not game.approach(1,7).is_empty(),"Tail-adjacent enemy is attackable")
	# Ground move backwards must include an explicit free turn.
	place(7,Vector2i(11,8),1)
	var route_choices=game.paths(7)
	var route=route_choices[Vector2i(8,8)].route
	expect(route[1].cost==0 and route[1].facing==-1,"Backwards movement starts with a free turn")
	game.reachable=route_choices
	await game.move_unit(7,Vector2i(8,8))
	expect(game.can_place(7,game.units[7].pos),"Animated horse ends on a legal footprint")
	expect(game.units[7].visual.is_equal_approx(game.unit_center(7)),"Visual and logical centers agree")
	expect(game.units[7].anim=="idle","Walk returns to idle")
	# A legal flight route may cross occupied/blocked cells, but not land on them.
	place(3,Vector2i(3,2),1)
	game.reachable=game.paths(3)
	await game.move_unit(3,Vector2i(9,3))
	expect(game.units[3].lift==0.0 and game.units[3].anim=="idle","Flight lands and stops flapping")
	expect(game.units[3].visual.is_equal_approx(game.unit_center(3)),"Flight aligns both landing cells")
	# Impact timing: target health is unchanged throughout attack anticipation.
	place(0,Vector2i(6,4))
	place(4,Vector2i(7,4))
	game.units[0].total=500
	game.units[4].total=390
	game.units[4].retaliated=true
	var hp=game.units[4].total
	game.perform_attack(0,4,false)
	await create_timer(0.01).timeout
	expect(game.units[4].total==hp,"Damage waits for contact, not attack start")
	await create_timer(0.22).timeout
	expect(game.units[4].total<hp,"Damage arrives after contact")
	expect(game.units[0].anim=="idle" and game.units[4].anim=="idle","Hit and recovery finish before next action")
	# An area shot must hit a two-hex stack only once even if both halves are in range.
	place(3,Vector2i(8,6),1)
	place(0,Vector2i(7,5))
	place(6,Vector2i(12,2))
	game.units[3].total=450
	game.units[0].total=500
	game.units[6].shots=12
	var griffin_hp=game.units[3].total
	var target_hp=game.units[0].total
	await game.perform_attack(6,0,true)
	expect(griffin_hp-game.units[3].total==maxi(1,(target_hp-game.units[0].total)/2),"Cloud damage is deduplicated across head and tail")
	# Lethal hit holds the corpse pose and releases both cells for later movement.
	game.units[4].total=0
	await game.receive_hit(4,Vector2(1,0))
	expect(game.units[4].anim=="death" and is_zero_approx(game.units[4].death_angle),"Lethal hit fades without rotating a flat sprite")
	expect(game.occupant(game.units[4].pos)!=4,"Corpse does not block movement")
	game.queue_free()
	await process_frame
	await process_frame
	print("DOUBLE_HEX_TEST PASS: ",checks," checks; footprint, boundaries, corridor, flight, turn, tail contact, impact timing, cloud, death")
	quit()
