extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.animation_speed=100
 for u in g.units: u.total=0
 for id in [0,1,4]: g.units[id].total=1000
 g.units[0].sprite=20
 g.units[0].pos=Vector2i(5,4)
 g.units[4].pos=Vector2i(6,4)
 g.units[1].pos=Vector2i(7,4)
 for id in [0,1,4]: g.units[id].visual=g.unit_center(id)
 g.apply_creature_effects(0,4,false,50)
 assert(g.units[1].total==950,"Breath hits allied stack in next hex")
 g.units[1].total=1000
 g.units[1].pos=Vector2i(6,3)
 g.units[1].visual=g.unit_center(1)
 g.apply_creature_effects(0,4,false,50)
 assert(g.units[1].total==1000,"Breath is not a cone")
 g.units[0].sprite=30
 g.units[1].side=1
 g.units[1].pos=Vector2i(5,3)
 g.units[1].visual=g.unit_center(1)
 g.apply_creature_effects(0,4,false,50)
 assert(g.units[1].total==950,"Three-headed attack hits adjacent secondary enemy")
 g.units[1].side=0
 g.apply_creature_effects(0,4,false,50)
 assert(g.units[1].total==950,"Three-headed attack does not hit allies")
 g.units[0].sprite=7
 for i in range(100): g.apply_creature_effects(0,4,false,1)
 assert(not g.units[4].has("curse_rounds"),"Undead immune to curse")
 g.units[4].undead=false
 for i in range(100): g.apply_creature_effects(0,4,false,1)
 assert(g.units[4].curse_rounds==3)
 g.units[0].sprite=19
 g.units[4].living=true
 for i in range(100): g.apply_creature_effects(0,4,false,1)
 assert(g.units[4].blind_rounds==3)
 print("H3 AREA PASS: breath geometry/friendly fire, three heads enemy-only, curse immunity, blind proc")
 quit()
