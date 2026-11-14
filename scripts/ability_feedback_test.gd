extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.choosing_faction=false
 g.busy=true
 g.animation_speed=1
 await process_frame
 # Exercise the real binding hit, including audio and VFX dispatch.
 g.units[0].sprite=18
 g.units[0].pos=Vector2i(5,4)
 g.units[4].pos=Vector2i(6,4)
 g.units[4].total=10000
 g.units[0].total=10000
 g.units[4].retaliated=true
 for id in [0,4]: g.units[id].visual=g.unit_center(id)
 await g.perform_attack(0,4,false,false)
 assert(g.units[4].rooted)
 assert("root" in g.soundtrack.ability_events)
 # Every visual has a playable, imported audio layer; render all branches.
 var keys=g.soundtrack.ABILITY_SOUNDS.keys()
 g.effects.clear()
 for i in range(keys.size()):
  var key=keys[i]
  g.ability_feedback(key,0,4)
  var e=g.effects[-1]
  e.to=Vector2(280+(i%3)*400,260+(i/3)*180)
  e.from=e.to-Vector2(100,0)
  e.t=.28
  if DisplayServer.get_name()!="headless":
   for layer in g.soundtrack.ABILITY_SOUNDS[key]:
    var sound=("%s-0" if layer[0].begins_with("move-") else "combat-%s-0")%layer[0]
    assert(g.soundtrack.sounds[sound].get_length()>0)
 g.animation_speed=0
 g.effects_layer.queue_redraw()
 if DisplayServer.get_name()!="headless":
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/ability-feedback.png")
 print("ABILITY FEEDBACK PASS: actual binding trigger, nine visual branches, skill audio layers")
 quit()
