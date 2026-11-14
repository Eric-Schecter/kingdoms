extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await create_timer(.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/map-selection.png")
 for id in range(4):
  game.choosing_faction=true
  game.select_map(id)
  assert(game.map_id==id and game.soundtrack.music_map==id)
  assert(game.soundtrack.music.stream!=null)
  game.soundtrack.toggle_music()
  assert(game.soundtrack.music.stream_paused)
  game.soundtrack.toggle_music()
  game.army_factions=[0,1]
  game.new_battle()
  game.choosing_faction=false
  game.next_round()
  assert(game.validate_layout())
  for unit in range(game.units.size()):
   assert(game.paths(unit).size()>1)
  await create_timer(.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/map-%s.png"%game.Battlefields.KEYS[id])
  await create_timer(6.0).timeout
 print("MAPS PASS: four maps, distinct music, mute state, deployment and legal movement")
 quit()
