extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 var a=g.soundtrack
 assert(not a.start_played)
 g.choose_faction(0)
 assert(a.start_played and a.start_player.playing)
 assert(a.start_player.stream.get_length()>4.5)
 assert(a.music.volume_db<a.MUSIC_GAIN_DB[g.map_id]-20)
 await create_timer(.3).timeout
 var pos=a.start_player.get_playback_position()
 a.play_battle_start()
 assert(a.start_player.get_playback_position()>=pos)
 a.toggle_music()
 assert(a.start_player.stream_paused)
 a.toggle_music()
 assert(not a.start_player.stream_paused)
 await create_timer(4.6).timeout
 assert(absf(a.music.volume_db-a.MUSIC_GAIN_DB[g.map_id])<.1)
 a.reset_result()
 a.play_battle_start()
 a.play_result(true)
 assert(not a.start_player.playing)
 print("START AUDIO PASS: faction entry, once-only, music toggle, BGM recovery, result interruption")
 quit()
