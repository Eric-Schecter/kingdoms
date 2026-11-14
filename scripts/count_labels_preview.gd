extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game._process(0)
 for id in game.badge_rects:
  for other in range(game.units.size()):
   assert(not game.badge_rects[id].intersects(game.badge_body_rect(other)),"Opening label overlaps creature")
 # Dense melee fixture with single- and two-hex creatures.
 for id in range(game.units.size()): game.units[id].total=0
 var places={2:Vector2i(6,4),3:Vector2i(6,6),7:Vector2i(8,6),10:Vector2i(6,8),12:Vector2i(8,4),13:Vector2i(8,8)}
 for id in places:
  game.units[id].total=game.units[id].max_total
  game.units[id].pos=places[id]
  game.units[id].visual=game.unit_center(id)
 game._process(0)
 for id in game.badge_rects:
  for other in places:
   assert(not game.badge_rects[id].intersects(game.badge_body_rect(other)),"Melee label overlaps creature")
  for other in game.badge_rects:
   if id!=other: assert(not game.badge_rects[id].intersects(game.badge_rects[other]))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/count-labels-melee.png")
 print("COUNT_LABELS PASS: deployment and crowded melee body/label avoidance")
 quit()
