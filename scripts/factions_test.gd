extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 assert(game.sprites.size()==35 and game.ABILITIES.size()==35)
 assert(game.faction_towns.size()==5)
 game.opponent_rng.seed=71623
 for faction in range(5):
  var seen={}
  for trial in range(200):
   var enemy=game.random_opponent(faction)
   assert(enemy!=faction and enemy>=0 and enemy<5)
   seen[enemy]=true
  assert(seen.size()==4)
 for kind in range(35):
  var actor=game.UnitPose.new()
  actor.setup(game.sprites[kind],kind)
  assert(actor.storybook and actor.story_frames.size()==9)
  actor.free()
 game.queue_free()
 await process_frame
 for faction in range(5):
  game=load("res://main.tscn").instantiate()
  root.add_child(game)
  game.choose_faction(faction)
  assert(game.validate_layout() and game.units.size()==14)
  assert(game.army_factions[game.player_side]==faction)
  assert(game.army_factions[1-game.player_side]!=faction)
  var actual=[]
  for u in game.units:
   if u.side==game.player_side: actual.append(u.sprite)
  assert(actual==game.Catalog.ROSTERS[faction])
  game.queue_free()
  await process_frame
 print("FACTIONS PASS: five selectable armies, 35 nine-frame sheets, valid seven-stack deployments")
 quit()
