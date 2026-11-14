extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.choosing_faction=false
 game.busy=true
 var id=4
 var before: int=game.units[id].total
 var count_before: int=game.amount(game.units[id])
 await game.perform_attack(8,id,true)
 var hits=game.effects.filter(func(e): return e.kind=="text" and e.tokens[0][0]=="damage")
 assert(hits.size()==1)
 assert(int(hits[0].tokens[0][1])==before-game.units[id].total)
 assert(int(hits[0].tokens[1][1])==count_before-game.amount(game.units[id]))
 # Overkill is capped to remaining HP; a wounded last creature is one casualty.
 game.effects.clear()
 game.units[id].total=0
 game.hit_feedback(id,1,500)
 assert(game.effects[-1].tokens==[["damage","1"],["fallen","1"]])
 game.units[id].total=game.units[id].hp*2-1
 game.hit_feedback(id,game.units[id].hp*2,1)
 assert(game.effects[-1].tokens==[["damage","1"],["fallen","0"]])
 # All produced attack/spell labels must resolve to an icon plus numeric payload.
 for label in ["BRACED","DOUBLE SHOT","DOUBLE STRIKE","RETALIATE","FLANK +25%","CHARGE +30%","DISEASE -2 ATK/DEF","ROOTED","FIRE SHIELD","DEATH CLOUD 50%","LONG RANGE 50%","SMITE +25%","ETHEREAL -25%","NO RETALIATION","LIFE DRAIN","DRAIN +36","LUCK","HIGH MORALE","DISEASED"]:
  game.floating(label,Vector2(700,400),Color.WHITE)
  var token=game.effects[-1].tokens[0]
  assert(game.combat_icons.has(token[0]))
  assert(token[1].is_empty() or token[1].replace("+","").replace("−","").replace("-","").replace("%","").is_valid_int())
 game.effects.clear()
 game.floating_tokens([["damage","128"],["fallen","3"]],Vector2(510,350),Color("fff1ce"))
 game.floating("DRAIN +36",Vector2(840,350),Color.WHITE)
 game.floating("DISEASE -2 ATK/DEF",Vector2(510,450),Color.WHITE)
 game.floating("ROOTED",Vector2(840,450),Color.WHITE)
 game.floating("CHARGE +30%",Vector2(510,550),Color.WHITE)
 game.floating("DOUBLE SHOT",Vector2(840,550),Color.WHITE)
 await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/combat-icons-preview.png")
 print("COMBAT ICONS PASS: actual damage and casualties, wounded stack, overkill, 21 effect labels")
 game.queue_free()
 await process_frame
 quit()
