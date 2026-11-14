extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.choosing_faction=false
	game.opening_battle=false
	for u in game.units: u.total=0
	for i in range(5):
		game.units[i].total=100
		game.units[i].large=false
		game.units[i].living=true
		game.units[i].side=1
	game.units[0].side=0
	game.units[0].pos=Vector2i(3,4)
	game.units[0].sprite=20
	game.units[0].large=true
	game.units[0].facing=1
	game.units[1].pos=Vector2i(6,4)
	game.units[2].pos=Vector2i(7,4)
	game.units[2].side=0
	game.units[3].pos=Vector2i(5,3)
	game.units[4].pos=Vector2i(12,8)
	assert(game.secondary_attack_targets(0,1,false,Vector2i(5,4),1)==[2],"Breath preview must use the planned destination and include allies")
	game.units[0].pos=Vector2i(5,4)
	assert(game.secondary_attack_targets(0,1,false)==[2],"Resolved breath must match the preview")
	game.units[0].sprite=6
	game.units[0].pos=Vector2i(2,4)
	game.units[3].living=false
	assert(game.secondary_attack_targets(0,1,true)==[2],"Cloud must include living allies and exclude undead")
	game.units[2].large=true
	game.units[2].facing=-1
	assert(game.secondary_attack_targets(0,1,true).count(2)==1,"Double-hex stacks must only appear once")
	game.units[0].sprite=30
	game.units[0].large=false
	game.units[0].pos=Vector2i(5,4)
	game.units[3].living=true
	assert(game.secondary_attack_targets(0,1,false)==[3],"Three-headed attack must exclude allies")
	game.current=0
	game.ai_preview=true
	game.ai_target=1
	game.ai_plan={"head":Vector2i(5,4),"facing":1,"route":[{"head":Vector2i(5,4),"facing":1}]}
	assert(game.attack_preview_targets()==[1,3],"AI preview includes primary and secondary targets")
	if "--capture-preview" in OS.get_cmdline_user_args():
		for i in range(5):
			game.units[i].visual=game.unit_center(i)
		game._process(0.0)
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://output/attack-preview.png")
	game.ended=true
	assert(game.attack_preview_targets().is_empty())
	game.ended=false
	game.opening_battle=true
	assert(game.attack_preview_targets().is_empty())
	print("ATTACK PREVIEW PASS: breath, cloud, triple, friendly fire, large stacks, AI, input locks")
	quit()
