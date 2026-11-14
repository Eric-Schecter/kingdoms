extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.army_factions=[0,1]
 g.choosing_faction=false
 g.new_battle()
 g.busy=true
 var q=g.initiative_preview()
 assert(q[0]==g.current and q.size()==28)
 var first=g.current
 g.order.push_front(first)
 assert(g.initiative_preview()[1]==first,"Morale repeats current immediately")
 g.order.pop_front()
 var delayed=g.order.pop_front()
 g.waiting.append(delayed)
 q=g.initiative_preview()
 assert(q[13]==delayed,"Waiting stack moves behind normal actions")
 g.units[delayed].total=0
 assert(delayed not in g.initiative_preview())
 assert(g.morale(g.units[0])==1,"Same faction + angel - enemy bone dragon")
 assert(g.morale(g.units[4])==0,"Undead morale immunity")
 assert(g.luck(g.units[0])==1)
 var plain=g.damage_range(g.units[0],g.units[4],false)
 var lucky=g.damage_range(g.units[0],g.units[4],false,{},false,true)
 assert(lucky.x>plain.x and lucky.y>plain.y)
 g.units[13].sprite=34
 assert(g.luck(g.units[0])==0,"Devil negates basic luck")
 g.hero_morale[0]=-10
 assert(g.morale(g.units[0])==-3)
 g.hero_morale[0]=10
 assert(g.morale(g.units[0])==3)
 g.hero_morale[0]=0
 g.new_battle()
 g.busy=true
 await create_timer(.3).timeout
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/initiative-fortune.png")
  g.open_creature_details(0,g.units[0].pos)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/fortune-details.png")
 print("INITIATIVE FORTUNE PASS: rolling order, morale repeat, wait, death, cohesion, immunity, luck damage, devil, clamps")
 quit()
