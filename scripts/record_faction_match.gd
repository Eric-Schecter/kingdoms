extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await create_timer(3.0).timeout
 var click=InputEventMouseButton.new()
 click.button_index=MOUSE_BUTTON_LEFT
 click.pressed=true
 click.position=game.faction_card(3).get_center()
 game._unhandled_input(click)
 assert(game.army_factions==[3,1])
 await create_timer(1.5).timeout
 game.animation_speed=2.0
 game.button_action("auto")
 var elapsed=0.0
 while not game.ended:
  await create_timer(0.5).timeout
  elapsed+=0.5
  assert(game.validate_layout())
  if elapsed>600:
   push_error("Recording timeout")
   quit(1)
   return
 await create_timer(3.0).timeout
 print("FACTION RECORD PASS: Tower vs Necropolis, round ",game.round_no," duration ",elapsed)
 quit()
