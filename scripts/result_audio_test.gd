extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 for side in [0,1]:
  for victory in [true,false]:
   game.new_battle()
   game.player_side=side
   var losing=1-side if victory else side
   for u in game.units:
    if u.side==losing: u.total=0
   assert(game.check_end())
   assert(game.soundtrack.result_played)
   assert(game.soundtrack.result_player.playing)
   assert(game.soundtrack.result_player.stream.resource_path.ends_with("result-%s.wav"%("victory" if victory else "defeat")))
   await create_timer(.4).timeout
   var position=game.soundtrack.result_player.get_playback_position()
   game.check_end()
   assert(game.soundtrack.result_player.get_playback_position()>=position)
   assert(game.soundtrack.music.volume_db<game.soundtrack.MUSIC_GAIN_DB[0]-10)
 game.new_battle()
 assert(not game.soundtrack.result_played)
 assert(not game.soundtrack.result_player.playing)
 assert(game.soundtrack.music.volume_db==game.soundtrack.MUSIC_GAIN_DB[0])
 print("RESULT AUDIO PASS: both player sides, win/loss, no duplicate playback, restart restores music")
 game.queue_free()
 await process_frame
 quit()
