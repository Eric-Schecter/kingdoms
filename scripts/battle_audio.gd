extends Node
var start_player: AudioStreamPlayer
var start_played=false
var lucky_impact_player: AudioStreamPlayer
var proc_player: AudioStreamPlayer
var result_player: AudioStreamPlayer
var result_played=false
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer]=[]
var sounds={}
var next_voice=0
var music_enabled=true
func _ready():
 if DisplayServer.get_name()=="headless": return
 for name in ["swing","steel","arrow","magic","magic-impact","claw","impact","bone"]:
  sounds[name]=load("res://assets/audio/%s.wav"%name)
 for family in ATTACK_FAMILIES:
  for take in range(3):
   var key="combat-%s-%d"%[family,take]
   sounds[key]=load("res://assets/audio/%s.wav"%key)
 for i in range(8):
  var player=AudioStreamPlayer.new()
  player.volume_db=-9
  add_child(player)
  voices.append(player)
 for family in ["boots","armor","bones","shuffle","hooves","feathers","leather","spectral","stone","wood","slither","fire","paws","giant"]:
  for take in range(3):
   var key="move-%s-%d"%[family,take]
   sounds[key]=load("res://assets/audio/%s.wav"%key)
 for i in range(4):
  var player=AudioStreamPlayer.new()
  add_child(player)
  movement_voices.append(player)
 start_player=AudioStreamPlayer.new()
 start_player.volume_db=-8
 add_child(start_player)
 lucky_impact_player=AudioStreamPlayer.new()
 lucky_impact_player.volume_db=-2
 add_child(lucky_impact_player)
 proc_player=AudioStreamPlayer.new()
 proc_player.volume_db=-3
 add_child(proc_player)
 result_player=AudioStreamPlayer.new()
 result_player.volume_db=-6
 add_child(result_player)
 music=AudioStreamPlayer.new()
 music.volume_db=-16
 add_child(music)
 set_battlefield(0)
func toggle_music():
 music_enabled=not music_enabled
 if music: music.stream_paused=not music_enabled
 if start_player: start_player.stream_paused=not music_enabled
func play_sound(name: String):
 if voices.is_empty() or not sounds.has(name): return
 var player=voices[next_voice]
 next_voice=(next_voice+1)%voices.size()
 player.stream=sounds[name]
 player.pitch_scale=1.0
 player.volume_db=-9
 player.play()

# One profile per creature catalog entry; pitch expresses weight within a family.
const MOVE_PROFILES=["armor","boots","armor","feathers","bones","shuffle","spectral","hooves","boots","hooves","feathers","spectral","leather","leather","hooves","boots","boots","feathers","wood","hooves","leather","boots","stone","stone","boots","spectral","slither","giant","paws","paws","paws","giant","hooves","fire","spectral"]
const MOVE_PITCH=[1.1,1.1,.85,1.0,1.1,.8,.85,.8,1.0,.95,.8,1.1,1.2,.65,1.1,.8,1.2,1.15,.75,1.15,.75,1.3,1.15,.75,.95,1.25,.85,.65,1.35,1.1,.85,.9,.8,.9,.75]
var movement_voices: Array[AudioStreamPlayer]=[]
var movement_serial=0
var movement_last_take={}
var movement_rng=RandomNumberGenerator.new()
var movement_events=0
func movement_interval(kind: int) -> float:
 var family=MOVE_PROFILES[kind]
 if family in ["spectral","fire"]: return .40
 if family in ["feathers","leather"]: return .44
 return .28
func play_movement(kind: int, landing: bool=false):
 movement_events+=1
 if movement_voices.is_empty(): return
 var family=MOVE_PROFILES[kind]
 if landing and family in ["feathers","leather"]: family="paws"
 var previous=movement_last_take.get(family,-1)
 var take=(previous+1+movement_rng.randi_range(0,1))%3
 movement_last_take[family]=take
 var player=movement_voices[movement_serial%movement_voices.size()]
 movement_serial+=1
 player.stream=sounds["move-%s-%d"%[family,take]]
 player.pitch_scale=lerpf(1.0,MOVE_PITCH[kind],0.5)*[1.0,1.025,.985][take]
 player.volume_db=-14 if landing else (-18 if family in ["spectral","fire"] else -12)
 player.play()

const ATTACK_FAMILIES=["blade","thrust","claw","heavy","bow","crossbow","holy","arcane","death","firebolt","lightning","flesh-hit","metal-hit","bone-hit","stone-hit","magic-hit","holy-hit","arcane-hit","death-hit","firebolt-hit","lightning-hit"]
var combat_serial=0
var combat_last={}
var combat_events=[]
func attack_family(kind: int, ranged: bool) -> String:
 if ranged:
  return {1:"crossbow",16:"bow",21:"bow",6:"death",8:"holy",24:"arcane",27:"lightning",29:"firebolt"}.get(kind,"bow")
 if kind in [0,7,9,14,17,19]: return "thrust"
 if kind in [3,5,12,13,20,28,30]: return "claw"
 if kind in [15,18,22,23,27,31]: return "heavy"
 if kind in [6,11,25,33]: return "arcane"
 return "blade"
func play_combat(family: String, impact: bool=false):
 combat_events.append(family)
 if combat_events.size()>64: combat_events.pop_front()
 if voices.is_empty(): return
 var take=(combat_last.get(family,-1)+1+movement_rng.randi_range(0,1))%3
 combat_last[family]=take
 var player=voices[next_voice]
 next_voice=(next_voice+1)%voices.size()
 player.stream=sounds["combat-%s-%d"%[family,take]]
 player.pitch_scale=[1.0,.97,1.035][take]
 player.volume_db=-7 if impact else -10
 player.play()
func attack_release(kind: int,ranged: bool):
 play_combat(attack_family(kind,ranged))
func attack_impact(kind: int,target: int,ranged: bool):
 var family=attack_family(kind,ranged)
 if family in ["holy","arcane","death","firebolt","lightning"]:
  play_combat(family+"-hit",true)
 else:
  var material="metal-hit" if target in [0,2,7,9,23,27] else ("bone-hit" if target in [4,6,13] else ("stone-hit" if target==22 else "flesh-hit"))
  play_combat(material,true)

# Per-track gain: the snow and graveyard recordings are much quieter than
# the other masters. Match their average playback level near -30 dBFS.
const MUSIC_GAIN_DB=[-11.0,5.0,10.0,-17.0]
var music_map=-1
var music_fade: Tween
func set_battlefield(id: int):
 if not music or music_map==id: return
 music_map=id
 if music_fade: music_fade.kill()
 var path="res://assets/audio/storybook-battle.wav" if id==0 else "res://assets/audio/music/%s.ogg"%["valley","snow","graveyard","volcano"][id]
 var stream=load(path).duplicate()
 if stream is AudioStreamWAV:
  stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin=0
  stream.loop_end=stream.data.size()/(4 if stream.stereo else 2)
 else: stream.loop=true
 music.stream=stream
 music.volume_db=-40
 music.play()
 music.stream_paused=not music_enabled
 music_fade=create_tween()
 music_fade.tween_property(music,"volume_db",MUSIC_GAIN_DB[id],.65)

func reset_result():
 if lucky_impact_player: lucky_impact_player.stop()
 if proc_player: proc_player.stop()
 start_played=false
 if start_player: start_player.stop()
 result_played=false
 if result_player: result_player.stop()
 if music:
  if music_fade: music_fade.kill()
  music.volume_db=MUSIC_GAIN_DB[maxi(0,music_map)]

func play_result(victory: bool):
 if result_played: return
 result_played=true
 if start_player: start_player.stop()
 if not result_player: return
 result_player.stream=load("res://assets/audio/result-%s.wav"%("victory" if victory else "defeat"))
 result_player.play()
 if music:
  if music_fade: music_fade.kill()
  music_fade=create_tween()
  music_fade.tween_property(music,"volume_db",MUSIC_GAIN_DB[maxi(0,music_map)]-12.0,.25)

# Layer recorded Foley from the existing licensed combat library. No hero casting.
const ABILITY_SOUNDS={
 "death_blow":[["heavy",0.72,-5],["death-hit",0.8,-10]],
 "curse":[["death",0.7,-8],["arcane-hit",0.8,-14]],
 "blind":[["holy-hit",1.35,-8],["arcane",1.5,-16]],
 "disease":[["flesh-hit",0.65,-10],["death",0.9,-15]],
 "root":[["heavy",1.2,-11],["move-wood",0.8,-7]],
 "fire":[["firebolt-hit",0.8,-7],["firebolt",1.1,-12]],
 "drain":[["death",1.2,-10],["holy-hit",0.7,-14]],
 "breath":[["firebolt",0.6,-6],["firebolt-hit",0.65,-9]],
 "triple":[["claw",0.75,-6],["flesh-hit",0.85,-10]]}
var ability_events: Array[String]=[]
func play_ability(skill: String):
 if not ABILITY_SOUNDS.has(skill): return
 ability_events.append(skill)
 if ability_events.size()>64: ability_events.pop_front()
 if voices.is_empty(): return
 for layer in ABILITY_SOUNDS[skill]:
  var key=("%s-0" if layer[0].begins_with("move-") else "combat-%s-0")%layer[0]
  var player=voices[next_voice]
  next_voice=(next_voice+1)%voices.size()
  player.stream=sounds[key]
  player.pitch_scale=layer[1]
  player.volume_db=layer[2]
  player.play()

func play_battle_start():
 if start_played or result_played: return
 start_played=true
 if not start_player: return
 start_player.stream=load("res://assets/audio/battle-start.wav")
 start_player.play()
 start_player.stream_paused=not music_enabled
 if music:
  if music_fade: music_fade.kill()
  music.volume_db=MUSIC_GAIN_DB[maxi(0,music_map)]-22.0
  music_fade=create_tween()
  music_fade.tween_interval(2.8)
  music_fade.tween_property(music,"volume_db",MUSIC_GAIN_DB[maxi(0,music_map)],1.6)

func play_proc(cue: String):
 if cue=="luck" and lucky_impact_player:
  lucky_impact_player.stream=load("res://assets/audio/lucky-impact.wav")
  lucky_impact_player.play()
 if not proc_player: return
 proc_player.stream=load("res://assets/audio/proc-%s.wav"%cue)
 proc_player.play()
