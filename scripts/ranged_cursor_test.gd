extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.choosing_faction=false
 g.busy=false
 g.current=1
 g.units[1].pos=Vector2i(1,4)
 g.units[4].pos=Vector2i(11,4)
 assert(g.stack_distance(1,4)==10)
 assert(g.ranged_cursor(1,4)=="double_shot")
 var full=g.damage_range(g.units[1],g.units[4],true)
 g.units[4].pos=Vector2i(12,4)
 assert(g.stack_distance(1,4)==11)
 assert(g.ranged_cursor(1,4)=="ranged_half")
 var half=g.damage_range(g.units[1],g.units[4],true)
 assert(absi(full.x-half.x*2)<=1 and absi(full.y-half.y*2)<=1)
 for id in [1,4]: g.units[id].visual=g.unit_center(id)
 root.grab_focus()
 g.cursor_inside=true
 g.get_viewport().warp_mouse(g.cell_center(g.units[4].pos))
 await create_timer(.25).timeout
 g.cursor_inside=true
 g.update_action_cursor()
 assert(g.action_cursor_key=="ranged_half")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/ranged-half-cursor.png")
 print("RANGED CURSOR PASS: 10 hex full, 11 hex half damage, matching visible cursor")
 quit()
