extends SceneTree
## Same runtime actor, enlarged for inspecting frame registration.
var actor
var small
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(960,640)
 root.content_scale_size=Vector2i(960,640)
 var background=ColorRect.new()
 background.color=Color("263746")
 background.size=Vector2(960,640)
 root.add_child(background)
 for x in [260,720]:
  var unit=load("res://scripts/unit_pose.gd").new()
  root.add_child(unit)
  unit.setup(load("res://assets/unit_3.png"),3)
  unit.position=Vector2(x,480)
  if x==260:
   actor=unit
   unit.scale=Vector2(2.4,2.4)
  else: small=unit
 assert(actor.painted)
 assert(actor.painted_frames.size()==6)
 var label=Label.new()
 label.text="2D GRIFFIN  /  FRAME ANIMATION\nLeft: enlarged inspection    Right: battle size"
 label.position=Vector2(28,560)
 label.add_theme_font_size_override("font_size",22)
 root.add_child(label)
 DirAccess.make_dir_recursive_absolute("/tmp/t17-2d-preview")
 for i in range(48):
  actor.update_pose("fly",float(i)/12.0,1.0,0.0)
  small.update_pose("fly",float(i)/12.0,1.0,0.0)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/t17-2d-preview/frame_%03d.png"%i)
  await create_timer(1.0/12.0).timeout
 print("GRIFFIN_2D_PREVIEW PASS: six painted poses loaded, 48 frames captured")
 quit()
