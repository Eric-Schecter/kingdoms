extends SceneTree
var game
func _initialize(): call_deferred("run")
func place(id,p):
 game.units[id].pos=p
 game.units[id].visual=game.unit_center(id)
func run():
 game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.animation_speed=100
 assert(game.units.size()==14 and game.validate_layout())
 var sides=[0,0]
 for u in game.units: sides[u.side]+=1
 assert(sides==[7,7])
 for id in range(8,14):
  var actor=load("res://scripts/unit_pose.gd").new()
  actor.setup(game.sprites[id],id)
  assert(actor.storybook and actor.story_frames.size()==9)
  actor.free()
 for id in [9,10,13]: assert(game.footprint(id).size()==2)
 for id in [10,11,12,13]: assert(game.units[id].flying)
 # Check reverse flight for both a single-hex ghost and two-hex angel.
 for flyer in [11,10]:
  place(flyer,Vector2i(7,2))
  game.units[flyer].facing=1
  var paths=game.paths(flyer)
  var destination=Vector2i(5,2)
  assert(paths.has(destination))
  await game.move_unit(flyer,destination,paths[destination])
  assert(game.units[flyer].pos==destination,"Reverse flight lands on requested hex")
  assert(game.units[flyer].visual.is_equal_approx(game.unit_center(flyer)))
  if flyer==10:
   assert(game.footprint(flyer).size()==2)
   var cells=game.footprint(flyer)
   await game.turn_unit(flyer,-game.units[flyer].facing)
   for cell in cells: assert(cell in game.footprint(flyer))
  place(flyer,Vector2i(11,7) if flyer==11 else Vector2i(1,10))
 # Isolate ability fixtures from unrelated stacks / dragon aura.
 for id in range(14): game.units[id].total=0
 for id in [0,8,9,10,11,12,13]: game.units[id].total=game.units[id].max_total
 place(0,Vector2i(7,4));place(8,Vector2i(6,4));place(13,Vector2i(13,9))
 assert(game.damage_range(game.units[8],game.units[0],false)==game.damage_range(game.units[8],game.units[0],true),"Monk has no melee penalty")
 place(10,Vector2i(6,4));place(11,Vector2i(7,4))
 var smite=game.damage_range(game.units[10],game.units[11],true)
 game.units[11].undead=false
 var plain=game.damage_range(game.units[10],game.units[11],true)
 assert(smite.y>plain.y)
 game.units[11].undead=true
 var spectral=game.damage_range(game.units[10],game.units[11],false)
 assert(spectral.y<smite.y,"Ghost resists melee")
 place(13,Vector2i(8,4))
 assert(game.effective_attack(game.units[0])==game.units[0].atk-2)
 place(13,Vector2i(13,9))
 assert(game.effective_attack(game.units[0])==game.units[0].atk)
 place(12,Vector2i(6,4))
 game.units[12].total=200
 var hp=game.units[12].total
 await game.perform_attack(12,0,false)
 assert(game.units[12].total>hp and not game.units[0].retaliated,"Drain and no retaliation")
 game.units[12].total=game.units[12].max_total-1
 game.units[0].total=game.units[0].max_total
 await game.perform_attack(12,0,false)
 assert(game.units[12].total==game.units[12].max_total,"Drain cap")
 var route=[]
 for x in range(2,6): route.append({"head":Vector2i(x,6),"facing":1,"cost":x-2})
 assert(game.movement_traits(9,{"route":route}).charge)
 print("EXPANSION_TEST PASS: fourteen sheets/stacks, deployment, flight, two hexes, monk, smite, ethereal, dread, drain, charge")
 quit()
