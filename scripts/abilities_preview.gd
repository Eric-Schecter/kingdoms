extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 await process_frame
 game.busy=true
 game.current=7
 game.units[0].pos=Vector2i(6,4)
 game.units[7].pos=Vector2i(7,4)
 for id in [0,7]: game.units[id].visual=game.unit_center(id)
 game.units[7].move_steps=3
 game.units[7].charge=true
 game.perform_attack(7,0,false)
 await create_timer(0.25).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/ability-braced.png")
 await create_timer(2.8).timeout
 game.current=0
 root.warp_mouse(Vector2i(400,820))
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/ability-tooltip.png")
 print("ABILITIES_PREVIEW PASS: brace/charge exchange and expanded tooltip")
 quit()
