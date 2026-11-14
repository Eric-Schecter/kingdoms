extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 await create_timer(1.0).timeout
 assert(game.ui_icons.size()==9)
 assert(game.soundtrack.music.playing)
 game.button_action("music")
 assert(game.soundtrack.music.stream_paused)
 game.button_action("music")
 assert(not game.soundtrack.music.stream_paused)
 assert(game.buttons.size()==7)
 for key in ["grid","speed"]:
  var click=InputEventMouseButton.new()
  click.button_index=MOUSE_BUTTON_LEFT
  click.pressed=true
  click.position=game.buttons[key].get_center()
  game._unhandled_input(click)
 assert(not game.grid_on)
 assert(game.animation_speed==2.0)
 assert(not game.has_method("cast_spell"))
 game.animation_speed=1.0
 game.grid_on=true
 root.warp_mouse(Vector2i(80,40))
 await create_timer(0.15).timeout
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/storybook-ui.png")
 root.warp_mouse(Vector2i(game.buttons.defend.get_center()))
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/storybook-ui-tooltip.png")
 print("UI_PREVIEW PASS: nine icons, seven hitboxes, music pause/resume, grid/speed click paths")
 quit()
