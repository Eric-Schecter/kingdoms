extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 assert(game.units.size()==14 and game.round_roster.size()==14)
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/full-width-ui.png")
 game.button_action("settings")
 assert(game.settings_open)
 game.button_action("music")
 assert(not game.soundtrack.music_enabled)
 game.button_action("music")
 assert(game.soundtrack.music_enabled)
 game.settings_open=false
 game.auto_on=true
 game.ai_turn()
 while not game.ended:
  await create_timer(0.5).timeout
  assert(game.validate_layout())
  for id in range(game.units.size()):
   var u=game.units[id]
   if u.total>0 and u.anim=="idle":
    assert(u.visual.is_equal_approx(game.unit_center(id)),"Idle actor and hex occupancy diverged")
 await create_timer(1.5).timeout
 print("RECORDED_MATCH PASS: completed round ",game.round_no)
 quit()
