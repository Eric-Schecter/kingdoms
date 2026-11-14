extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await create_timer(0.4).timeout
 assert(game.choosing_faction and game.current==-1 and game.round_no==0)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/faction-selection.png")
 var click=InputEventMouseButton.new()
 click.button_index=MOUSE_BUTTON_LEFT
 click.pressed=true
 click.position=game.faction_card(1).get_center()
 game._unhandled_input(click)
 assert(not game.choosing_faction and game.player_side==1)
 assert(game.army_factions[1]==1 and game.army_factions[0]!=1)
 # Verify player-side AI guard and spell allegiance without waiting through enemy moves.
 game.current=12
 game.busy=false
 await game.ai_turn()
 assert(not game.busy and game.current==12)
 assert(not game.has_method("cast_spell"))
 for u in game.units:
  if u.side==0: u.total=0
 assert(game.check_end())
 game.queue_free()
 await process_frame
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 click.position=game.faction_card(0).get_center()
 game._unhandled_input(click)
 assert(game.player_side==0 and game.army_factions[1]!=0)
 print("FACTION_SELECT PASS: picture clicks, both factions, AI ownership, no hero casting, end state")
 quit()
