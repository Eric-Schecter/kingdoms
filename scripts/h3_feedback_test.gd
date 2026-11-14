extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.animation_speed=50
 # Compare actual jousting with/without pikeman immunity.
 var rider=game.units[9]
 var target=game.units[4]
 rider.move_steps=0
 var plain=game.damage_range(rider,target,false)
 rider.move_steps=6
 assert(game.damage_range(rider,target,false).x>plain.x)
 target.sprite=0
 var charged=game.damage_range(rider,target,false)
 rider.move_steps=0
 assert(game.damage_range(rider,target,false)==charged)
 target.sprite=4
 # Vampire Lord heals the full actual damage, never beyond initial stack HP.
 game.units[12].pos=Vector2i(6,4)
 game.units[0].pos=Vector2i(7,4)
 game.units[12].total=80
 var hp=game.units[0].total
 await game.perform_attack(12,0,false)
 assert(game.units[12].total==80+hp-game.units[0].total)
 assert(not game.units[0].retaliated)
 # Bind survives turns and ends when its source dies.
 game.units[0].rooted=true
 game.units[0].bound_by=8
 assert(game.speed(game.units[0])==0)
 game.units[8].total=0
 game.receive_hit(8,Vector2.RIGHT)
 assert(not game.units[0].rooted)
 # No spell API or key/action buttons remain.
 assert(not game.has_method("cast_spell"))
 for key in game.ICON_KEYS: assert(not key.begins_with("spell"))
 game.new_battle()
 game.choosing_faction=false
 game.current=1
 game.reachable=game.paths(1)
 game.busy=false
 await create_timer(.1).timeout
 if DisplayServer.get_name()!="headless":
  var point=game.units[4].visual-Vector2(0,40)
  game.get_viewport().warp_mouse(point)
  var event=InputEventMouseMotion.new()
  event.position=point
  game._unhandled_input(event)
  assert(game.inspected==4)
  await create_timer(.25).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/h3-interaction.png")
  game.open_creature_details(7,game.units[7].pos)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/h3-abilities.png")
 print("H3 FEEDBACK PASS: jousting immunity, full life drain, binding release, removed spells, enemy hover")
 game.queue_free()
 await process_frame
 quit()
