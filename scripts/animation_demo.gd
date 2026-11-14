extends SceneTree
## Reproducible visual smoke test. --record saves viewport frames for ffmpeg.
var game
var recording=false
var frame=0

func _initialize(): call_deferred("run")

func place(id: int, head: Vector2i):
	game.units[id].pos=head
	game.units[id].visual=game.unit_center(id)

func record_frames():
	DirAccess.make_dir_recursive_absolute("/tmp/t17-animation-frames")
	for name in DirAccess.get_files_at("/tmp/t17-animation-frames"):
		if name.begins_with("frame_") and name.ends_with(".jpg"):
			DirAccess.remove_absolute("/tmp/t17-animation-frames/"+name)
	while recording:
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image()
		img.resize(960,int(round(960.0*img.get_height()/img.get_width()/2.0))*2,Image.INTERPOLATE_LANCZOS)
		img.save_jpg("/tmp/t17-animation-frames/frame_%04d.jpg" % frame,0.91)
		frame+=1
		await create_timer(1.0/15.0).timeout

func move(id: int, head: Vector2i):
	game.current=id
	game.reachable=game.paths(id)
	await game.move_unit(id,head)
	assert(game.validate_layout())

func run():
	game=load("res://main.tscn").instantiate()
	game.choosing_faction=false
	root.add_child(game)
	await process_frame
	game.busy=true
	game.animation_speed=1.0
	place(0,Vector2i(4,4))
	place(1,Vector2i(2,2))
	place(2,Vector2i(5,6))
	place(3,Vector2i(2,8))
	place(4,Vector2i(7,4))
	place(5,Vector2i(10,6))
	place(6,Vector2i(12,2))
	place(7,Vector2i(12,8))
	assert(game.validate_layout())
	recording="--record" in OS.get_cmdline_user_args()
	if recording: record_frames()
	await create_timer(0.4).timeout
	await move(3,Vector2i(7,8))
	await move(7,Vector2i(10,8))
	await move(0,Vector2i(6,4))
	await game.perform_attack(0,4,false)
	await move(2,Vector2i(9,6))
	await game.perform_attack(2,5,false)
	await game.perform_attack(2,5,false,false,true)
	game.current=1
	await game.perform_attack(1,6,true)
	game.current=6
	await game.perform_attack(6,3,true)
	await move(7,Vector2i(8,8))
	game.current=7
	await game.perform_attack(7,3,false)
	# Finish on a clearly visible lethal reaction.
	game.units[4].total=1
	game.current=0
	await game.perform_attack(0,4,false)
	await create_timer(0.6).timeout
	recording=false
	await create_timer(0.12).timeout
	print("ANIMATION_DEMO PASS: recorded ",frame," frames; animated flight, gallop, walk, attack, shot, hit, death")
	quit()
