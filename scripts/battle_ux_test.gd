extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.choosing_faction=false
 g.army_factions=[0,1]
 g.new_battle()
 g.current=0
 g.busy=false
 g.reachable=g.paths(0)
 var destination=Vector2i(-1,-1)
 for cell in g.reachable:
  if g.occupant(cell)<0: destination=cell; break
 assert(destination.x>=0)
 # Simulate a picture overlapping a legal empty destination.
 var pos=g.cell_center(destination)
 g.units[1].visual=pos+Vector2(0,35)
 await create_timer(.1).timeout
 assert(g.pick_creature(pos)>=0)
 assert(g.pick_action_target(pos)==-1)
 assert(g.pick_action_target(g.cell_center(g.units[4].pos))==4)
 await create_timer(.3).timeout
 assert(g.actors[0].material.get_shader_parameter("highlighted"))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/active-unit-large-queue.png")
 for u in g.units:
  if u.side!=g.player_side: u.total=0
 assert(g.check_end())
 var e=InputEventMouseButton.new()
 e.button_index=MOUSE_BUTTON_RIGHT
 e.pressed=true
 e.position=g.units[0].visual
 g._unhandled_input(e)
 g.open_creature_details(0,g.units[0].pos)
 assert(g.detail_id==-1 and g.reachable.is_empty())
 await create_timer(.1).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/victory-no-dimming.png")
 assert(g.buttons.size()==1 and g.buttons.has("restart"))
 var before=[g.grid_on,g.animation_speed,g.auto_on,g.soundtrack.music_enabled,AudioServer.is_bus_mute(0)]
 for key in ["settings","grid","speed","auto","music","mute","wait","defend"]: g.button_action(key)
 assert(not g.settings_open)
 assert(before==[g.grid_on,g.animation_speed,g.auto_on,g.soundtrack.music_enabled,AudioServer.is_bus_mute(0)])
 assert(g.actors[0].visible)
 assert(not g.actors[0].material.get_shader_parameter("highlighted"))
 print("BATTLE UX PASS: overlap resolves to move, occupied enemy targeting, active outline, result input lock and surviving art")
 quit()
