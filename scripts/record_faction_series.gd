extends SceneTree

func _initialize(): call_deferred("run")

func run():
	# macOS skips drawing occluded windows; keep capture visible while recording.
	var capture=load("res://scripts/movie_capture_driver.gd").new()
	capture.process_priority=1000
	root.add_child(capture)
	root.always_on_top=true
	root.grab_focus()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	var left=0
	var right=1
	var map=0
	var preview_seconds=0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--left="): left=int(arg.get_slice("=",1))
		if arg.begins_with("--right="): right=int(arg.get_slice("=",1))
		if arg.begins_with("--map="): map=int(arg.get_slice("=",1))
		if arg.begins_with("--preview-seconds="): preview_seconds=float(arg.get_slice("=",1))
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.proc_triggered.connect(func(cue,id): print("PROC_CAPTURE ",cue," frame=",capture.frames," unit=",id))
	game.select_map(map)
	game.army_factions=[left,right]
	game.player_side=0
	game.choosing_faction=false
	game.animation_speed=2.0
	game.auto_on=false
	game.new_battle()
	game.soundtrack.play_battle_start()
	await create_timer(4.8).timeout
	game.auto_on=true
	if not game.busy: game.ai_turn()
	var elapsed=0.0
	while not game.ended:
		await create_timer(0.5).timeout
		elapsed+=0.5
		if not game.validate_layout() or elapsed>600:
			push_error("Recording layout failure or timeout")
			quit(1)
			return
		if preview_seconds>0 and elapsed>=preview_seconds: break
	await create_timer(8.0).timeout
	print("SERIES RECORD PASS: " if game.ended else "SERIES PREVIEW PASS: ",left," vs ",right," map ",map," rounds ",game.round_no," seconds ",elapsed)
	quit()
