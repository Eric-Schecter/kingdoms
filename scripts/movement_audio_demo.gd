extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.soundtrack.toggle_music()
 for kind in [0,1,4,5,9,3,12,11,23,18,26,27,30,33]:
  var faction=0
  for f in range(5):
   if kind in game.Catalog.ROSTERS[f]: faction=f
  game.choosing_faction=true
  game.army_factions=[faction,1]
  game.new_battle()
  game.choosing_faction=false
  var id=-1
  for i in range(game.units.size()):
   if game.units[i].side==0 and game.units[i].sprite==kind: id=i
   else: game.units[i].total=0
  assert(id>=0)
  game.current=id
  game.busy=true
  game.units[id].pos=Vector2i(4,5)
  game.units[id].visual=game.unit_center(id)
  game.obstacles.clear()
  game.reachable=game.paths(id)
  await create_timer(.5).timeout
  var before=game.soundtrack.movement_events
  var target=Vector2i(7,5)
  var route=game.paths(id,true)
  await game.move_unit(id,target,route[target])
  assert(game.soundtrack.movement_events>before)
  assert(game.units[id].pos==target)
  await create_timer(.45).timeout
 print("MOVEMENT AUDIO PASS: 14 profiles triggered by actual ground and flying routes")
 quit()
