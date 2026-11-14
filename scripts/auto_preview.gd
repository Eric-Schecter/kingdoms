extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 await process_frame
 game.auto_on=true
 game.ai_turn()
 var seen={}
 var initial_roster=game.round_roster.duplicate()
 for i in range(720):
  await process_frame
  if game.round_no==1: assert(game.round_roster==initial_roster)
  if game.units[game.current].anim in ["walk","fly"] and not seen.has("saved_moving"):
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://output/moving-no-marker.png")
   seen.saved_moving=true
  if game.ai_preview:
   seen[game.ai_phase]=true
   if game.ai_phase=="PLAN MOVE" and not seen.has("saved_move"):
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://output/auto-move.png")
    seen.saved_move=true
   if game.ai_target>=0 and not seen.has("saved_target"):
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://output/auto-target.png")
    seen.saved_target=true
 assert(seen.has("SELECT UNIT"))
 assert(seen.has("PLAN MOVE"))
 assert(seen.has("saved_target"))
 assert(game.validate_layout())
 print("AUTO_PREVIEW PASS: ",seen)
 quit()
