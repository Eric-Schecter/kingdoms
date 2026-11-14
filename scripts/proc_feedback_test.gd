extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.choosing_faction=false
 g.busy=true
 g.animation_speed=2
 g.units[0].visual=Vector2(490,450)
 g.units[4].visual=Vector2(930,450)
 g.proc_feedback("morale",0)
 g.proc_feedback("luck",4)
 assert(g.effects[-1].life==2.0)
 assert(g.soundtrack.proc_player.playing)
 assert(g.soundtrack.lucky_impact_player.playing)
 assert(g.soundtrack.lucky_impact_player.stream.get_length()>.4)
 assert(g.soundtrack.proc_player.stream.resource_path.ends_with("proc-luck.wav"))
 await create_timer(.3).timeout
 assert(g.effects[-1].t<.5,"Proc timing ignores 2x speed")
 g.effects.append({"kind":"critical","from":Vector2(710,410),"t":0.0,"life":.60})
 g.settings_open=true
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/proc-feedback-clear.png")
 assert(g.buttons.settings.position.x==1352)
 assert(g.buttons.music.position.x>1200)
 g.proc_feedback("panic",0)
 assert(g.soundtrack.proc_player.stream.resource_path.ends_with("proc-panic.wav"))
 print("PROC FEEDBACK PASS: distinct audio, readable real-time duration, right-aligned settings")
 quit()
