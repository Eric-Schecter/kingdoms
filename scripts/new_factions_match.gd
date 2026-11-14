extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var faction=2
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--faction="): faction=int(arg.trim_prefix("--faction="))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--map="): game.select_map(int(arg.trim_prefix("--map=")))
 Engine.time_scale=30
 game.animation_speed=8
 game.auto_on=true
 game.choose_faction(faction)
 var started=Time.get_ticks_msec()
 while not game.ended:
  await create_timer(0.5).timeout
  assert(game.validate_layout())
  if Time.get_ticks_msec()-started>120000:
   push_error("Match timeout")
   quit(1)
   return
 print("NEW FACTION MATCH PASS: ",game.Catalog.NAMES[faction]," map ",game.map_id," round ",game.round_no)
 quit()
