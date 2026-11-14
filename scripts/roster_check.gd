extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 await process_frame
 var roster=game.round_roster.duplicate()
 assert(roster.size()==14)
 var first=game.current
 game.guard()
 assert(game.current!=first)
 assert(game.round_roster==roster)
 assert(not game.order.has(first))
 game.busy=true
 await RenderingServer.frame_post_draw
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/fixed-roster.png")
 print("ROSTER_CHECK PASS: 14 cards retained after action; current advanced")
 quit()
