extends SceneTree
var actors=[]
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(1680,760)
 root.content_scale_size=Vector2i(1680,760)
 var background=ColorRect.new()
 background.color=Color("e8dfbd")
 background.size=Vector2(1680,760)
 root.add_child(background)
 var names=["PIKEMEN","MARKSMEN","CRUSADERS","GRIFFINS","SKELETONS","ZOMBIES","LICHES","DREAD KNIGHTS","MONKS","KNIGHTS","ANGELS","GHOSTS","VAMPIRES","BONE DRAGONS"]
 for i in range(14):
  var actor=load("res://scripts/unit_pose.gd").new()
  root.add_child(actor)
  actor.setup(load("res://assets/unit_%d.png"%mini(i,7)),i)
  assert(actor.storybook,"Missing storybook troop %d"%i)
  assert(actor.story_frames.size()==9)
  actor.position=Vector2(120+(i%7)*240,290+(i/7)*330)
  actor.scale=Vector2(1.2,1.2)
  actors.append(actor)
  var label=Label.new()
  label.text=names[i]
  label.position=actor.position+Vector2(-100,24)
  label.add_theme_color_override("font_color",Color("493629"))
  root.add_child(label)
 var title=Label.new()
 title.position=Vector2(30,20)
 title.add_theme_font_size_override("font_size",24)
 title.add_theme_color_override("font_color",Color("493629"))
 root.add_child(title)
 DirAccess.make_dir_recursive_absolute("/tmp/t17-army-preview")
 for n in range(96):
  var phase=n/24
  var state=["idle","walk","attack","hit"][phase]
  title.text="STORYBOOK ARMY / "+state.to_upper()
  for i in range(14):
   var action=state
   if state=="walk" and i in [3,10,11,12,13]: action="fly"
   if state=="attack" and i in [1,6,8]: action="shoot"
   actors[i].update_pose(action,float(n%24)/12.0,1.5,0.0)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/t17-army-preview/frame_%03d.png"%n)
  await create_timer(1.0/12.0).timeout
 print("ARMY_PREVIEW PASS: 14 troops, 126 poses, idle/walk/fly/attack/shoot/hit")
 quit()
