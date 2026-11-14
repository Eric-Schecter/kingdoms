extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await create_timer(0.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/five-factions.png")
 game.queue_free()
 await process_frame
 for faction in [2,3,4]:
  game=load("res://main.tscn").instantiate()
  root.add_child(game)
  game.choose_faction(faction)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/%s-army.png"%game.Catalog.TOWNS[faction])
  game.queue_free()
  await process_frame
 print("NEW FACTION PREVIEWS PASS")
 quit()
