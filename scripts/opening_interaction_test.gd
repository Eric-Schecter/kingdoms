extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.choose_faction(0)
 assert(g.opening_battle and g.busy and g.current==-1 and g.reachable.is_empty())
 var blocked=InputEventMouseButton.new()
 blocked.pressed=true
 blocked.button_index=MOUSE_BUTTON_RIGHT
 blocked.position=g.units[0].visual-Vector2(0,20)
 g._unhandled_input(blocked)
 g.open_creature_details(0,g.units[0].pos)
 g.button_action("settings")
 assert(g.detail_id==-1 and not g.settings_open)
 var key=InputEventKey.new()
 key.pressed=true
 key.keycode=KEY_A
 g._unhandled_input(key)
 assert(not g.auto_on)
 g.ai_turn()
 assert(g.current==-1)
 await create_timer(5.1).timeout
 assert(not g.opening_battle and g.current>=0)
 assert(not g.reachable.is_empty())
 g.auto_on=false
 g.current=1
 g.busy=false
 g.reachable=g.paths(1)
 var target=-1
 for i in range(g.units.size()):
  if g.units[i].side!=g.player_side and g.units[i].total>0: target=i; break
 var event=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT
 event.pressed=true
 event.position=g.units[target].visual-Vector2(0,25)
 var hp=g.units[target].total
 g.animation_speed=10
 g._unhandled_input(event)
 assert(g.detail_id==-1,"Enemy left click must attack without modal")
 await create_timer(1).timeout
 assert(g.units[target].total<hp,"Direct click deals damage")
 event.button_index=MOUSE_BUTTON_RIGHT
 g._unhandled_input(event)
 assert(g.detail_id>=0,"Right click retains inspection")
 g.detail_id=-1
 root.grab_focus()
 g.cursor_inside=true
 g.get_viewport().warp_mouse(g.units[0].visual-Vector2(0,20))
 await create_timer(.15).timeout
 assert(g.actors[0].material.get_shader_parameter("highlighted"))
 assert(g.action_cursor_key in ["inspect","move"])
 assert(g.action_cursors.has(g.action_cursor_key))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/opening-interaction.png")
 g.busy=false
 g.current=1
 g.reachable=g.paths(1)
 for cell in g.reachable:
  if g.occupant(cell)<0:
   g.get_viewport().warp_mouse(g.cell_center(cell))
   break
 await create_timer(.12).timeout
 assert(g.action_cursor_key=="move")
 assert(Input.mouse_mode==Input.MOUSE_MODE_HIDDEN)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/mac-move-cursor.png")
 g.get_viewport().warp_mouse(g.units[target].visual-Vector2(0,20))
 await create_timer(.12).timeout
 assert(g.action_cursor_key=="double_shot")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/mac-attack-cursor.png")
 print("OPENING INPUT PASS: intro lock, music delay, range unlock, direct attack, right-click inspection, hover highlight")
 quit()
