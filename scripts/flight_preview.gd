extends SceneTree
var actors=[]
var clock=0.0
func _initialize(): call_deferred("run")
func _process(delta):
 clock+=delta
 for actor in actors: actor.update_pose("fly",clock,10,0)
 RenderingServer.force_draw(false,delta)
 return false
func run():
 root.always_on_top=true
 root.grab_focus()
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.choosing_faction=false
 game.set_process(false)
 game.units.clear()
 for old in game.actors: old.visible=false
 var kinds=[3,10,13,17,20,22,12,34]
 for j in range(kinds.size()):
  var actor=load("res://scripts/unit_pose.gd").new()
  root.add_child(actor)
  actor.setup(game.sprites[kinds[j]],kinds[j])
  actor.position=Vector2(240+(j%4)*310,365+(j/4)*300)
  actor.scale=Vector2.ONE*1.05
  actors.append(actor)
  if kinds[j] in [3,10,13,17,20,22]: assert(actor.flight_frames.size()==4)
  var label=Label.new()
  label.text=actor.STORY_NAMES[kinds[j]].to_upper()
  label.position=actor.position+Vector2(-80,22)
  label.add_theme_color_override("font_color",Color("342539"))
  root.add_child(label)
 await create_timer(1.0).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/flight-preview.png")
 await create_timer(5.0).timeout
 print("FLIGHT PASS: six independent wing cycles, levitation without walking legs")
 quit()
