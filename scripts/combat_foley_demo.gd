extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.soundtrack.toggle_music()
 for kind in [2,0,3,23,16,1,8,24,6,29,27]:
  var faction=0
  for f in range(5):
   if kind in game.Catalog.ROSTERS[f]: faction=f
  game.choosing_faction=true
  game.army_factions=[faction,1]
  game.new_battle()
  game.choosing_faction=false
  game.obstacles.clear()
  var id=-1
  for i in range(game.units.size()):
   if game.units[i].side==0 and game.units[i].sprite==kind: id=i
   elif i!=4: game.units[i].total=0
  var ranged=game.units[id].shots>0
  game.units[id].pos=Vector2i(5,5)
  game.units[4].pos=Vector2i(10 if ranged else 6,5)
  for i in [id,4]: game.units[i].visual=game.unit_center(i)
  game.units[4].total=5000
  game.units[4].retaliated=true
  game.current=id
  game.round_roster.assign([id,4])
  game.busy=true
  game.ai_preview=true
  game.ai_target=4
  game.ai_phase="AIM SHOT" if ranged else "SELECT ATTACK"
  await create_timer(.65).timeout
  game.ai_preview=false
  game.ai_target=-1
  var before=game.units[4].total
  await game.perform_attack(id,4,ranged)
  assert(game.units[4].total<before)
  assert(game.soundtrack.attack_family(kind,ranged) in game.soundtrack.combat_events)
  await create_timer(.55).timeout
 print("COMBAT FOLEY PASS: 11 attack families, release/impact events and damage; no target connector")
 quit()
