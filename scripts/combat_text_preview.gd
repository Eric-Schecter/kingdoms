extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.choosing_faction=false

 for map in [0,1,2,3]:
  game.choosing_faction=true
  game.select_map(map)
  for faction in range(5):
   game.army_factions=[faction,(faction+1)%5]
   game.choosing_faction=true
   game.new_battle()
   assert(game.validate_layout())
   for id in range(game.units.size()):
    var cells=game.footprint(id)
    var edge=0 if game.units[id].side==0 else game.COLS-1
    assert(cells.any(func(cell): return cell.x==edge))
  game.choosing_faction=false
  game._process(0.0)
  game.floating("−128",Vector2(450,370),Color.WHITE)
  game.floating("DOUBLE SHOT",Vector2(450,365),Color.WHITE)
  game.floating("DRAIN +36",Vector2(750,440),Color.WHITE)
  game.floating("DISEASE -2 ATK/DEF",Vector2(750,435),Color.WHITE)
  game.queue_redraw()
  game.effects_layer.queue_redraw()
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/combat-text-%d.png"%map)
  await create_timer(4.0).timeout
  assert(game.soundtrack.music.playing)
  assert(absf(game.soundtrack.music.volume_db-game.soundtrack.MUSIC_GAIN_DB[map])<0.1)
  print("MUSIC MAP ",map," GAIN ",game.soundtrack.music.volume_db," POSITION ",game.soundtrack.music.get_playback_position())
 print("COMBAT TEXT PREVIEW PASS")
 game.queue_free()
 await process_frame
 quit()
