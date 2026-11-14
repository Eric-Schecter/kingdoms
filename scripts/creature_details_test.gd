extends SceneTree
func _initialize(): call_deferred("run")
func click(game,p):
 var e=InputEventMouseButton.new()
 e.button_index=MOUSE_BUTTON_LEFT
 e.pressed=true
 e.position=p
 game._unhandled_input(e)
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.army_factions=[0,1]
 game.choosing_faction=false
 game.new_battle()
 await create_timer(.2).timeout
 click(game,game.units[game.current].visual-Vector2(0,30))
 assert(game.detail_id==-1 and game.reachable.size()>1,"Current creature reveals movement range without modal")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/movement-range.png")
 click(game,game.units[0].visual-Vector2(0,30))
 assert(game.detail_id==0,"Click own body opens details")
 click(game,Vector2(985,195))
 assert(game.detail_id==-1)
 game.current=1
 game.busy=false
 game.units[4].pos=Vector2i(8,4)
 game.units[4].visual=game.unit_center(4)
 game.units[4].diseased=true
 game.units[4].rooted=true
 await process_frame
 click(game,game.units[4].visual-Vector2(0,25))
 assert(game.detail_id==4 and game.can_detail_attack())
 var before=game.units[4].total
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/creature-details.png")
 assert(game.units[4].total==before,"Inspect does not attack")
 game.animation_speed=30
 click(game,Vector2(720,665))
 assert(game.detail_id==-1)
 await create_timer(.8).timeout
 assert(game.units[4].total<before,"Explicit Shoot confirms damage")
 print("DETAILS PASS: ally/enemy body clicks, close, read-only inspection, explicit attack")
 quit()
