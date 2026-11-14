extends SceneTree
var game
var checks=0
func _initialize(): call_deferred("run")
func check(value: bool,label: String):
 checks+=1
 if not value:
  push_error(label)
  quit(1)
  assert(value,label)
func place(id: int,p: Vector2i):
 game.units[id].pos=p
 game.units[id].visual=game.unit_center(id)
func run():
 game=load("res://main.tscn").instantiate()
 game.choosing_faction=false
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.animation_speed=100
 check(game.units[0].hp==12 and game.units[7].hp==70,"new health values")
 check(game.units[1].shots==12 and game.units[6].shots==8,"ammunition")
 # Straight movement vs turn; bonus must not leak into retaliation.
 var route=[]
 for x in range(9,5,-1): route.append({"head":Vector2i(x,6),"facing":-1,"cost":9-x})
 var plan={"route":route}
 check(game.movement_traits(7,plan).charge,"three straight hexes charge")
 route[2].head=Vector2i(7,5)
 check(not game.movement_traits(7,plan).charge,"bent path cannot charge")
 route[2].head=Vector2i(7,6)
 game.units[7].charge=false
 var base=game.damage_range(game.units[7],game.units[2],false)
 var charged=game.damage_range(game.units[7],game.units[2],false,plan)
 check(charged.x>base.x and charged.y>base.y,"charge changes damage")
 game.units[7].charge=true
 check(game.damage_range(game.units[7],game.units[2],false,{},true)==base,"no charge on retaliation")
 # Flank counts another allied stack, not just self or second footprint.
 place(4,Vector2i(6,4));place(0,Vector2i(7,4));place(5,Vector2i(12,8))
 check(not game.flanked(game.units[4],game.units[0]),"isolated skeleton no flank")
 var alone=game.damage_range(game.units[4],game.units[0],false)
 place(5,Vector2i(8,4))
 check(game.flanked(game.units[4],game.units[0]),"adjacent ally enables flank")
 check(game.damage_range(game.units[4],game.units[0],false).x>alone.x,"flank modifies damage")
 # Pike can kill approaching attacker before its blow.
 game.units[4].total=6
 game.units[4].move_steps=2
 var pike_hp=game.units[0].total
 await game.perform_attack(4,0,false)
 check(game.units[4].total==0,"braced strike happens first")
 check(game.units[0].total==pike_hp and game.units[0].retaliated,"brace consumes one retaliation and cancels killed attacker")
 # Disease applies on active melee, changes stats, expires after target action.
 game.units[4].total=390
 game.units[5].total=24
 game.units[0].retaliated=true
 await game.perform_attack(5,0,false)
 check(game.units[0].diseased,"living target receives disease")
 check(game.effective_attack(game.units[0])==game.units[0].atk-2,"disease attack penalty")
 check(game.effective_defense(game.units[0])==game.units[0].def-2,"disease defense penalty")
 game.current=0
 game.order.assign([1])
 game.next_turn()
 check(not game.units[0].diseased,"disease expires at end of target activation")
 place(4,Vector2i(7,4))
 game.units[4].retaliated=true
 await game.perform_attack(5,4,false)
 check(not game.units[4].diseased,"undead immune to disease")
 # Range six is full, seven is half.
 place(1,Vector2i(1,2));place(4,Vector2i(7,2))
 var near=game.damage_range(game.units[1],game.units[4],true)
 place(4,Vector2i(8,2))
 var far=game.damage_range(game.units[1],game.units[4],true)
 check(abs(near.y-2*far.y)<=1,"range over six halves damage")
 print("ABILITIES_TEST PASS: ",checks," checks")
 quit()
