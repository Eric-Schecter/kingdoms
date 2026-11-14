extends SceneTree
## Same runtime actor, enlarged for inspecting frame registration.
var actor
var small
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(960,640)
 root.content_scale_size=Vector2i(960,640)
 var background=ColorRect.new()
 background.color=Color("e8dfbd")
 background.size=Vector2(960,640)
 root.add_child(background)
 for x in [330,770]:
  var unit=load("res://scripts/unit_pose.gd").new()
  root.add_child(unit)
  unit.setup(load("res://assets/unit_3.png"),3)
  unit.position=Vector2(x,480)
  if x==330:
   actor=unit
   unit.scale=Vector2(2.4,2.4)
  else: small=unit
 assert(actor.storybook)
 assert(actor.story_frames.size()==9)
 var label=Label.new()
 label.text="STORYBOOK GRIFFIN / IDLE - FLIGHT - ATTACK - HIT\nLeft: enlarged inspection    Right: battle size"
 label.add_theme_color_override("font_color",Color("493629"))
 label.position=Vector2(28,560)
 label.add_theme_font_size_override("font_size",22)
 root.add_child(label)
 DirAccess.make_dir_recursive_absolute("/tmp/t17-storybook-preview")
 for i in range(72):
  var state="idle" if i<12 else ("fly" if i<44 else ("attack" if i<60 else "hit"))
  var elapsed=float(i)/12.0
  if state=="attack": elapsed=float(i-44)/12.0
  elif state=="hit": elapsed=float(i-60)/12.0
  actor.update_pose(state,elapsed,1.0,0.0)
  small.update_pose(state,elapsed,1.0,0.0)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/t17-storybook-preview/frame_%03d.png"%i)
  await create_timer(1.0/12.0).timeout
 print("GRIFFIN_2D_PREVIEW PASS: nine storybook poses loaded, 72 frames captured")
 quit()
