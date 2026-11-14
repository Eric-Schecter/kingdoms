extends Node2D

const Battlefields=preload("res://scripts/battlefields.gd")
var map_id=0
var map_textures: Array[Texture2D]=[]
const Catalog=preload("res://scripts/faction_catalog.gd")
var army_factions=[0,1]
const COLS = 15
const ROWS = 11
const GOLD = Color("a77c39")
const IVORY = Color("49392d")
const MUTED = Color("796b54")
const BLUE = Color("426b91")
const RED = Color("815783")
var number_font: Font
var font: SystemFont
var serif: SystemFont
var background: Texture2D
var faction_towns: Array[Texture2D]=[]
var sprites: Array[Texture2D] = []
var units: Array[Dictionary] = []
var order: Array[int] = []
var waiting: Array[int] = []
var round_roster: Array[int] = []
var initiative_offset=0
var initiative_slide=0.0
var initiative_tween: Tween
# Both scenario heroes have Basic Luck; no spells or artifacts are required.
var hero_luck=[1,1]
var hero_morale=[0,0]

func initiative_preview() -> Array[int]:
	var result: Array[int]=[]
	if current>=0 and units[current].total>0: result.append(current)
	for id in order:
		if units[id].total>0: result.append(id)
	var delayed=waiting.duplicate()
	delayed.sort_custom(func(a,b): return speed(units[a])<speed(units[b]) if speed(units[a])!=speed(units[b]) else units[a].side<units[b].side)
	for id in delayed:
		if units[id].total>0: result.append(id)
	var upcoming: Array[int]=[]
	for id in range(units.size()):
		if units[id].total>0: upcoming.append(id)
	upcoming.sort_custom(func(a,b): return speed(units[a])>speed(units[b]) if speed(units[a])!=speed(units[b]) else units[a].side<units[b].side)
	result.append_array(upcoming)
	return result

func advance_initiative():
	initiative_offset=0
	if initiative_tween: initiative_tween.kill()
	initiative_slide=96.0
	initiative_tween=create_tween()
	initiative_tween.tween_property(self,"initiative_slide",0.0,.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

var current = -1
var round_no = 0
var hovered = Vector2i(-1,-1)
var inspected = -1
var detail_id=-1
var detail_target=Vector2i(-1,-1)
var grid_on = true
var auto_on = false
var busy = false
var ai_preview=false
var ai_plan={}
var moving_plan={}
var moving_id=-1
var movement_sound_clock=0.0
var ai_target=-1
var ai_phase=""
var opening_battle=false
var choosing_faction=true
var player_side=0
var ended = false
var logs: Array[String] = []
var obstacles: Array[Vector2i] = [Vector2i(6,3),Vector2i(7,3),Vector2i(8,7),Vector2i(5,8)]
var reachable: Dictionary = {}
var effects: Array[Dictionary] = []
var combat_icons={}
const COMBAT_ICON_KEYS=["ranged_half","blind","curse","death_blow","hate","resist","breath","triple","inspect","move","damage","fallen","heal","guard","double_shot","double_strike","retaliation","charge","flank","disease","root","fire","cloud","range","smite","ethereal","no_retaliation","luck","morale"]
var clock = 0.0
var buttons: Dictionary = {}
var ui_icons: Array[Texture2D]=[]
var ui_hint=""
var settings_open=false
const ICON_KEYS=["wait","defend","speed","grid","auto","restart"]
const ACTION_ICON_INDICES=[0,1,5,6,7,8]
const ICON_HINTS=["Wait · W","Defend +20% · D","Animation speed · S","Hex grid · G","Auto battle · A","New battle · R"]
var audio: AudioStreamPlayer
var soundtrack: Node
var rng = RandomNumberGenerator.new()
var opponent_rng = RandomNumberGenerator.new()
var self_test = false
var battle_count = 0
const UnitPose = preload("res://scripts/unit_pose.gd")
var actors: Array[Node2D] = []
var animation_speed = 1.0
var badge_rects={}
var effects_layer: Node2D

func _ready():
	get_window().mouse_exited.connect(func(): cursor_inside=false; action_cursor_key=""; Input.mouse_mode=Input.MOUSE_MODE_VISIBLE)
	get_window().mouse_entered.connect(func(): cursor_inside=true)

	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for key in COMBAT_ICON_KEYS: combat_icons[key]=load("res://assets/ui/combat/%s.svg"%key)
	for key in Battlefields.KEYS:
		map_textures.append(load("res://assets/storybook/battlefield-%s.png"%key))
	for faction in Catalog.TOWNS:
		var town=faction+"-town"
		var town_path="res://assets/storybook/%s.png"%town
		if ResourceLoader.exists(town_path): faction_towns.append(load(town_path))
	if ResourceLoader.exists("res://assets/storybook/ui-icons.png"):
		var sheet=load("res://assets/storybook/ui-icons.png")
		for i in range(9):
			var icon=AtlasTexture.new()
			icon.atlas=sheet
			var cell=sheet.get_size()/3.0
			icon.region=Rect2(Vector2(i%3,i/3)*cell,cell)
			icon.filter_clip=true
			ui_icons.append(icon)
	# Engine-bundled sans font uses lining figures and includes math symbols.
	number_font = ThemeDB.fallback_font
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "PingFang SC", "Arial"])
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	if ResourceLoader.exists("res://assets/storybook/battlefield-valley.png"):
		background = load("res://assets/storybook/battlefield-valley.png")
	for i in range(Catalog.DATA.size()):
		var sheet=load("res://assets/storybook/%s-sheet.png"%UnitPose.STORY_NAMES[i])
		var frame=AtlasTexture.new()
		frame.atlas=sheet
		frame.region=Rect2(Vector2.ZERO,sheet.get_size()/3.0)
		sprites.append(frame)
	audio = AudioStreamPlayer.new()
	add_child(audio)
	soundtrack=load("res://scripts/battle_audio.gd").new()
	add_child(soundtrack)
	rng.seed = 11217
	opponent_rng.randomize()
	self_test = "--self-test" in OS.get_cmdline_user_args()
	if self_test: choosing_faction=false
	effects_layer=Node2D.new()
	effects_layer.z_index=2000
	add_child(effects_layer)
	effects_layer.draw.connect(func():
		if not ended and not choosing_faction:
			draw_effects(effects_layer)
			draw_interaction(effects_layer)
			for id in range(units.size()):
				if units[id].total>0:
					draw_unit_badge(id,effects_layer)
					AbilityFeedback.statuses(effects_layer,units[id],combat_icons)
		if detail_id>=0 and not choosing_faction: draw_creature_details(effects_layer)
		if software_action_cursor and not action_cursor_key.is_empty() and action_cursors.has(action_cursor_key):
			effects_layer.draw_texture_rect(action_cursors[action_cursor_key],Rect2(get_global_mouse_position()-Vector2(19,19),Vector2(38,38)),false)
	)
	new_battle()
	if "--capture" in OS.get_cmdline_user_args():
		get_tree().create_timer(1.0).timeout.connect(capture_frame)
	if self_test:
		auto_on = true
		Engine.time_scale = 25.0
		get_tree().create_timer(0.15).timeout.connect(ai_turn)

func new_battle():
	if soundtrack: soundtrack.reset_result()
	detail_id=-1
	obstacles.assign(Battlefields.OBSTACLES[map_id])
	for actor in actors: actor.queue_free()
	actors.clear()
	units.clear()
	order.clear()
	waiting.clear()
	logs.clear()
	effects.clear()
	round_no = 0
	ended = false
	busy = false
	current = -1
	# name, hp, attack, defense, min/max damage, speed, shots, sprite, count
	var data=Catalog.DATA.slice(0,14).duplicate(true)
	var slots=[[0,1,2,3,8,9,10],[4,5,6,7,11,12,13]]
	for team in range(2):
		for slot in range(7): data[slots[team][slot]]=Catalog.DATA[Catalog.ROSTERS[army_factions[team]][slot]].duplicate()
	# Seven stacks span the back edge; large stacks extend horizontally.
	var positions=[Vector2i(1,0),Vector2i(1,2),Vector2i(1,3),Vector2i(1,5),Vector2i(13,0),Vector2i(13,2),Vector2i(13,3),Vector2i(13,5),Vector2i(1,7),Vector2i(1,8),Vector2i(1,10),Vector2i(13,7),Vector2i(13,8),Vector2i(13,10)]
	for i in range(data.size()):
		var d=data[i]
		var side=0 if i in [0,1,2,3,8,9,10] else 1
		# Anchor every footprint to its army edge, including single-hex stacks.
		positions[i].x=(1 if d[8] in Catalog.LARGE else 0) if side==0 else (COLS-2 if d[8] in Catalog.LARGE else COLS-1)
		units.append({"name":d[0],"hp":d[1],"atk":d[2]+(3 if side==0 else 2),"def":d[3]+(2 if side==0 else 3),"lo":d[4],"hi":d[5],"speed":d[6],"shots":d[7],"sprite":d[8],"total":d[1]*d[9],"side":side,"pos":positions[i],"max_total":d[1]*d[9],"undead":d[8] in Catalog.UNDEAD,"living":d[8] not in Catalog.UNDEAD and d[8] not in Catalog.CONSTRUCT,"rooted":false,"flying":d[8] in Catalog.FLYING,"diseased":false,"move_steps":0,"charge":false,"retaliated":false,"guard":false,"visual":Vector2.ZERO,"flash":0.0,"large":d[8] in Catalog.LARGE,"facing":1 if side==0 else -1,"anim":"idle","anim_time":0.0,"anim_duration":1.0,"lift":0.0,"recoil":Vector2.ZERO,"death_angle":0.0,"turn_scale":1.0})
		units[-1].visual = unit_center(units.size()-1)
		var actor=UnitPose.new()
		add_child(actor)
		if sprites.size()==Catalog.DATA.size(): actor.setup(sprites[d[8]],d[8])
		var outline=ShaderMaterial.new()
		outline.shader=preload("res://scripts/hover_outline.gdshader")
		actor.material=outline
		actors.append(actor)
	log_line("The valley falls silent. Two armies take the field.")
	if not choosing_faction: next_round()

func amount(u: Dictionary) -> int:
	return ceili(float(u.total)/u.hp)

func cell_center(p: Vector2i) -> Vector2:
	return Vector2(180+p.x*73+(36.5 if p.y%2 else 0.0),250+p.y*46)

func hex_points(p: Vector2i, inset: float = 1.0) -> PackedVector2Array:
	var c = cell_center(p)
	return PackedVector2Array([c+Vector2(-36+inset,-15.333),c+Vector2(0,-30.667+inset),c+Vector2(36-inset,-15.333),c+Vector2(36-inset,15.333),c+Vector2(0,30.667-inset),c+Vector2(-36+inset,15.333)])

func valid(p: Vector2i) -> bool:
	return p.x>=0 and p.x<COLS and p.y>=0 and p.y<ROWS

func neighbors(p: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for delta in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(1 if p.y%2 else -1,-1),Vector2i(1 if p.y%2 else -1,1)]:
		if valid(p+delta): out.append(p+delta)
	return out

func footprint(id: int, head: Vector2i = Vector2i(-99,-99), facing: int = 0) -> Array[Vector2i]:
	var u=units[id]
	if head.x==-99: head=u.pos
	if facing==0: facing=u.facing
	var cells: Array[Vector2i]=[head]
	if u.large: cells.append(head-Vector2i(facing,0))
	return cells

func unit_center(id: int, head: Vector2i = Vector2i(-99,-99), facing: int = 0) -> Vector2:
	var cells=footprint(id,head,facing)
	var center=Vector2.ZERO
	for p in cells: center+=cell_center(p)
	return center/cells.size()

func occupant(p: Vector2i) -> int:
	for i in range(units.size()):
		if units[i].total>0 and footprint(i).has(p): return i
	return -1

func can_place(id: int, head: Vector2i, facing: int=0, flying_over: bool=false) -> bool:
	for p in footprint(id,head,facing):
		if not valid(p): return false
		if flying_over: continue
		if obstacles.has(p): return false
		var other=occupant(p)
		if other>=0 and other!=id: return false
	return true

func perimeter(id: int) -> Array[Vector2i]:
	var out: Array[Vector2i]=[]
	var cells=footprint(id)
	for p in cells:
		for n in neighbors(p):
			if not cells.has(n) and not out.has(n): out.append(n)
	return out

func touches(attacker: int, defender: int, head: Vector2i, facing: int=0) -> bool:
	var target=footprint(defender)
	for p in footprint(attacker,head,facing):
		for n in neighbors(p):
			if target.has(n): return true
	return false

func speed(u: Dictionary) -> int:
	return 0 if u.rooted else u.speed

func state_route(states: Dictionary, finish: Vector3i) -> Array[Dictionary]:
	var route: Array[Dictionary]=[]
	var cursor=finish
	while true:
		route.push_front({"head":Vector2i(cursor.x,cursor.y),"facing":cursor.z,"cost":states[cursor].cost})
		var previous: Vector3i=states[cursor].prev
		if previous==cursor: break
		cursor=previous
	return route

func paths(id: int, unlimited: bool = false) -> Dictionary:
	# A node includes orientation. Turning a two-hex creature swaps its head and
	# tail at zero movement cost, keeping exactly the same occupied footprint.
	var u=units[id]
	var origin=Vector3i(u.pos.x,u.pos.y,u.facing)
	var states={origin:{"cost":0,"prev":origin}}
	var queue: Array[Vector3i]=[origin]
	while not queue.is_empty():
		var state: Vector3i=queue.pop_front()
		var p=Vector2i(state.x,state.y)
		var cost: int=states[state].cost
		if u.large:
			var tail=p-Vector2i(state.z,0)
			var flip=Vector3i(tail.x,tail.y,-state.z)
			if not states.has(flip) or cost<states[flip].cost:
				states[flip]={"cost":cost,"prev":state}
				queue.push_front(flip)
		if not unlimited and cost>=speed(u): continue
		for n in neighbors(p):
			# Large creatures face into their horizontal movement. Vertical and
			# diagonal transitions remain legal; a turn is an explicit route node.
			var dx=cell_center(n).x-cell_center(p).x
			if u.large and dx*state.z<0: continue
			if not can_place(id,n,state.z,u.flying): continue
			var next=Vector3i(n.x,n.y,state.z)
			if states.has(next) and states[next].cost<=cost+1: continue
			states[next]={"cost":cost+1,"prev":state}
			queue.append(next)
	var result={}
	for state in states:
		var p=Vector2i(state.x,state.y)
		if not can_place(id,p,state.z): continue
		var entry={"cost":states[state].cost,"facing":state.z,"route":state_route(states,state)}
		if not result.has(p):
			result[p]=entry.duplicate()
			result[p].options=[]
		elif entry.cost<result[p].cost:
			result[p].cost=entry.cost
			result[p].facing=entry.facing
			result[p].route=entry.route
		result[p].options.append(entry)
	return result

func approach(attacker: int, defender: int, choices: Dictionary = {}, directional: bool=false) -> Dictionary:
	if choices.is_empty(): choices=reachable
	var best={}
	var best_cost=INF
	for head in choices:
		for option in choices[head].options:
			if touches(attacker,defender,head,option.facing):
				# Prefer the near side of the hex under the mouse for directional
				# melee attacks, with movement cost as the primary criterion.
				var preference=unit_center(attacker,head,option.facing).distance_to(cell_center(hovered)) if valid(hovered) else 0.0
				var cost=option.cost*10000.0+preference
				var cursor_direction=get_global_mouse_position()-unit_center(defender)
				if directional and cursor_direction.length()>12.0:
					var side=(unit_center(attacker,head,option.facing)-unit_center(defender)).normalized()
					cost=(1.0-side.dot(cursor_direction.normalized()))*100000.0+option.cost*100.0
				if cost<best_cost:
					best_cost=cost
					best=option.duplicate()
					best.head=head
	return best

func attack_cell(attacker: int, defender: int) -> Vector2i:
	var plan=approach(attacker,defender)
	return plan.head if not plan.is_empty() else Vector2i(-1,-1)

func next_round():
	round_no += 1
	waiting.clear()
	order.clear()
	for i in range(units.size()):
		if units[i].total>0:
			for field in ["disease_rounds","curse_rounds","blind_rounds"]: units[i][field]=maxi(0,units[i].get(field,0)-1)
			units[i].diseased=units[i].get("disease_rounds",0)>0
			if units[i].sprite==11:
				var heal=mini(units[i].max_total,amount(units[i])*units[i].hp)-units[i].total
				units[i].total+=heal
				if heal>0: floating("DRAIN +%d"%heal,units[i].visual-Vector2(0,100),BLUE)
			units[i].retaliated = false
			units[i].guard = false
			order.append(i)
	order.sort_custom(func(a,b): return speed(units[a])>speed(units[b]) if speed(units[a])!=speed(units[b]) else units[a].side<units[b].side)
	round_roster.assign(order)
	log_line("ROUND %d  —  banners rise again." % round_no)
	next_turn()

func next_turn():
	if opening_battle:
		busy=true
		reachable.clear()
		return
	if current>=0:
		units[current].move_steps=0
		units[current].charge=false
	if self_test and not validate_layout():
		get_tree().quit(1)
		return
	if check_end(): return
	if order.is_empty():
		if not waiting.is_empty():
			order.assign(waiting)
			order.sort_custom(func(a,b): return speed(units[a])<speed(units[b]) if speed(units[a])!=speed(units[b]) else units[a].side<units[b].side)
			waiting.clear()
		else:
			next_round()
			return
	current = order.pop_front()
	advance_initiative()
	if units[current].total<=0:
		next_turn()
		return
	if units[current].get("blind_rounds",0)>0:
		next_turn()
		return
	if units[current].get("morale_checked",-1)!=round_no:
		units[current].morale_checked=round_no
		if morale(units[current])<0 and rng.randf()<(-morale(units[current]))/12.0:
			busy=true
			proc_feedback("panic",current)
			get_tree().create_timer(.8).timeout.connect(next_turn)
			return
	reachable = paths(current)
	busy = false
	if units[current].side!=player_side or auto_on:
		busy = true
		get_tree().create_timer(0.55).timeout.connect(ai_turn)
	queue_redraw()

func check_end() -> bool:
	if ended: return true
	var living = [0,0]
	for u in units:
		if u.total>0: living[u.side]+=1
	if living[0]>0 and living[1]>0: return false
	ended = true
	inspected=-1
	detail_id=-1
	settings_open=false
	reachable.clear()
	soundtrack.play_result(living[player_side]>0)
	busy = false
	current = -1
	log_line(("VICTORY" if living[player_side]>0 else "DEFEAT")+" — "+(Catalog.NAMES[army_factions[0 if living[0]>0 else 1]].capitalize()+" prevails!"))
	if self_test:
		print("SELF_TEST PASS: battle completed in round ",round_no,"; living stacks ",living)
		get_tree().quit()
	return true

func can_shoot(id: int) -> bool:
	if units[id].shots<=0: return false
	for n in perimeter(id):
		var other=occupant(n)
		if other>=0 and units[other].side!=units[id].side: return false
	return true

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var aq=a.x-(a.y-(a.y%2))/2
	var bq=b.x-(b.y-(b.y%2))/2
	var dq=aq-bq
	var dr=a.y-b.y
	return maxi(abs(dq),maxi(abs(dr),abs(dq+dr)))

func stack_distance(a: int, b: int) -> int:
	var best=999
	for p in footprint(a):
		for q in footprint(b): best=mini(best,hex_distance(p,q))
	return best

const ABILITIES=["Immune to jousting bonus.", "Double ranged attack; half melee damage.", "Two melee attacks; retaliation after the first.", "Flying; unlimited retaliation.", "Undead; immune to morale and mind effects.", "Undead; 20% disease chance: -2 attack and defense for 3 rounds.", "Undead; death cloud damages adjacent living stacks, including allies.", "Undead; 20% curse (3 rounds), 20% double-damage death blow.", "Ranged; half melee damage.", "Jousting: +5% damage per hex travelled; pikemen ignore the bonus.", "Flying; allied morale +1; +50% damage against Devils.", "Undead; flying; regenerates the top creature at the start of each round.", "Undead; flying; no retaliation; restores actual damage dealt to living targets, resurrecting its own losses.", "Undead; flying; enemy morale -1.", "No special combat ability.", "20% magic resistance. No hero spells in this mode.", "Double ranged attack; half melee damage.", "Flying; enemy hero spells cost +2. Inactive without hero spells.", "Binding: target cannot move until the binding stack moves or dies.", "20% blinding attack; adjacent allied magic resistance +20%.", "Flying; two-hex breath, including friendly fire; immune to level 1-3 spells.", "Ranged; half melee damage.", "Flying; non-living, but affected by morale.", "Non-living; 75% spell damage reduction (not ranged attack reduction).", "Ranged; no melee penalty; hero spell cost -2 (inactive here).", "Flying; +50% damage against Efreet.", "No retaliation.", "Ranged; no melee penalty; mind immunity; hates Black Dragons (not present).", "No special combat ability.", "Ranged; half melee damage.", "Three-headed attack; no retaliation.", "No special combat ability.", "No special combat ability (summoning belongs to Pit Lords).", "Flying; fire immunity; 20% fire shield; +50% damage against Genies.", "Teleporting; no retaliation; enemy luck -1; +50% damage against Angels."]
const ABILITY_ICONS=[["guard"], ["double_shot"], ["double_strike"], ["retaliation"], ["fallen"], ["disease"], ["cloud"], ["curse", "death_blow"], [], ["charge"], ["morale", "hate"], ["heal"], ["heal", "no_retaliation"], ["morale"], [], ["resist"], ["double_shot"], ["resist"], ["root"], ["blind", "resist"], ["breath", "resist"], [], ["ethereal"], ["resist"], ["guard"], ["hate"], ["no_retaliation"], ["resist"], [], [], ["triple", "no_retaliation"], [], [], ["fire", "hate"], ["luck", "hate", "no_retaliation"]]

func effective_attack(u: Dictionary) -> int:
	return maxi(0,u.atk-(2 if u.get("diseased",false) else 0))

func army_has(side: int,kind: int) -> bool:
	return units.any(func(u): return u.side==side and u.sprite==kind and u.total>0)

func morale(u: Dictionary) -> int:
	if u.undead or u.sprite==23: return 0
	var factions=[]
	var undead_ally=false
	for ally in units:
		if ally.side!=u.side or ally.total<=0: continue
		undead_ally=undead_ally or ally.undead
		for f in range(Catalog.ROSTERS.size()):
			if ally.sprite in Catalog.ROSTERS[f] and f not in factions: factions.append(f)
	var cohesion=1 if factions.size()==1 else 2-factions.size()
	return clampi(cohesion+hero_morale[u.side]+int(army_has(u.side,10))-int(army_has(1-u.side,13))-int(undead_ally),-3,3)

func luck(u: Dictionary) -> int:
	return clampi(hero_luck[u.side]-int(army_has(1-u.side,34)),-3,3)

func hates(a: Dictionary,b: Dictionary) -> bool:
	return (a.sprite==10 and b.sprite==34) or (a.sprite==34 and b.sprite==10) or (a.sprite==25 and b.sprite==33) or (a.sprite==33 and b.sprite==25)

func effective_defense(u: Dictionary) -> int:
	var value=maxi(0,u.def-(2 if u.get("diseased",false) else 0))
	return value+floori(value*0.2) if u.guard else value

func movement_traits(id: int,plan: Dictionary) -> Dictionary:
	var steps=0
	var straight=true
	var previous=Vector2.ZERO
	var route: Array=plan.get("route",[])
	for i in range(1,route.size()):
		var delta=unit_center(id,route[i].head,route[i].facing)-unit_center(id,route[i-1].head,route[i-1].facing)
		if route[i].facing!=route[i-1].facing: straight=false
		if delta.length()<1: continue
		steps+=1
		var direction=delta.normalized()
		if previous!=Vector2.ZERO and not direction.is_equal_approx(previous): straight=false
		previous=direction
	return {"steps":steps,"charge":steps>=3 and straight}

func flanked(a: Dictionary,b: Dictionary) -> bool:
	for cell in perimeter(units.find(b)):
		var other=occupant(cell)
		if other>=0 and units[other]!=a and units[other].side==a.side: return true
	return false

func attack_labels(a: Dictionary,b: Dictionary,ranged: bool,plan: Dictionary={},retaliation: bool=false) -> String:
	var tags: Array[String]=[]
	var steps=a.get("move_steps",0) if plan.is_empty() else movement_traits(units.find(a),plan).steps
	if not ranged and not retaliation and a.sprite==9 and steps>0:
		tags.append("BRACED" if b.sprite==0 else "CHARGE +%d%%"%(5*steps))
	if ranged and a.sprite==6: tags.append("DEATH CLOUD")
	if ranged and ranged_distance_penalty(units.find(a),units.find(b)): tags.append("LONG RANGE 50%")
	if hates(a,b): tags.append("HATE +50%")
	if a.sprite in Catalog.NO_RETALIATION: tags.append("NO RETALIATION")
	return " · ".join(tags)

func ranged_distance_penalty(attacker: int, target: int) -> bool:
	return stack_distance(attacker,target)>10

func ranged_cursor(attacker: int, target: int) -> String:
	return "ranged_half" if ranged_distance_penalty(attacker,target) else "double_shot"

func damage_range(a: Dictionary,b: Dictionary,ranged: bool,plan: Dictionary={},retaliation: bool=false,lucky: bool=false) -> Vector2i:
	var diff=effective_attack(a)-effective_defense(b)
	var mult=1.0+minf(maxi(0,diff)*0.05,3.0)
	var reduction=1.0-minf(maxi(0,-diff)*0.025,0.7)
	if lucky: mult+=1.0
	if hates(a,b): mult+=0.5
	var steps=a.get("move_steps",0) if plan.is_empty() else movement_traits(units.find(a),plan).steps
	if not ranged and not retaliation and a.sprite==9 and b.sprite!=0: mult+=0.05*steps
	mult*=reduction
	if ranged and ranged_distance_penalty(units.find(a),units.find(b)): mult*=0.5
	if a.sprite in [1,6,8,16,21,29] and not ranged: mult*=0.5
	if retaliation and a.get("wake_blind",false): mult*=0.5
	var high=a.lo if a.get("curse_rounds",0)>0 else a.hi
	return Vector2i(maxi(1,int(amount(a)*a.lo*mult)),maxi(1,int(amount(a)*high*mult)))

func set_animation(id: int, state: String, duration: float=1.0):
	if state=="walk" and units[id].anim=="walk": return
	units[id].anim=state
	units[id].anim_time=0.0
	units[id].anim_duration=duration

func pause_animation(seconds: float):
	await get_tree().create_timer(seconds/animation_speed).timeout

func tween_motion(seconds: float, callback: Callable):
	var tween=create_tween()
	tween.tween_method(callback,0.0,1.0,seconds/animation_speed)
	await tween.finished

func turn_unit(id: int, facing: int):
	if units[id].facing==facing: return
	# Switch facing without squeezing the sprite through its paper-thin edge.
	if units[id].large: units[id].pos-=Vector2i(units[id].facing,0)
	units[id].facing=facing
	units[id].turn_scale=1.0

func face_target(id: int, target: int):
	var facing=1 if unit_center(target).x>=unit_center(id).x else -1
	await turn_unit(id,facing)

func restore_facing(id: int):
	if units[id].total>0:
		await turn_unit(id,1 if units[id].side==0 else -1)

func move_unit(id: int, target: Vector2i, plan: Dictionary = {}):
	if plan.is_empty():
		if not reachable.has(target): return
		plan=reachable[target]
	var route: Array=plan.route
	if route.is_empty(): return
	var movement=movement_traits(id,plan)
	if movement.steps>0:
		for bound in units:
			if bound.get("bound_by",-1)==id: bound.rooted=false; bound.bound_by=-1
	movement_sound_clock=0.0
	units[id].move_steps=movement.steps
	units[id].charge=movement.charge
	if movement.steps>0:
		moving_plan=plan
		moving_id=id
	if units[id].flying:
		var destination: Dictionary=route[-1]
		if destination.head==units[id].pos and destination.facing==units[id].facing: return
		var start: Vector2=units[id].visual
		var finish=unit_center(id,destination.head,destination.facing)
		if start.distance_to(finish)<0.1:
			await turn_unit(id,destination.facing)
			return
		var facing=1 if finish.x>=start.x else -1
		await turn_unit(id,facing)
		if units[id].sprite==34:
			set_animation(id,"fly",0.6)
			await tween_motion(0.25,func(t): units[id].phase_alpha=1.0-t)
			units[id].pos=destination.head
			units[id].facing=destination.facing
			units[id].visual=finish
			await tween_motion(0.25,func(t): units[id].phase_alpha=t)
			units[id].phase_alpha=1.0
			set_animation(id,"idle")
			moving_plan={}
			moving_id=-1
			return
		var duration=0.60+start.distance_to(finish)/550.0
		set_animation(id,"fly",duration)
		await tween_motion(duration,func(t):
			movement_sound_tick(id,t*duration)
			units[id].visual=start.lerp(finish,t)
			units[id].lift=58.0*smoothstep(0.0,0.16,t)*(1.0-smoothstep(0.82,1.0,t))
		)
		units[id].pos=destination.head if not units[id].large or destination.facing==facing else destination.head-Vector2i(destination.facing,0)
		units[id].facing=facing
		units[id].visual=finish
		units[id].lift=0.0
		set_animation(id,"land",0.45)
		if soundtrack.MOVE_PROFILES[units[id].sprite] not in ["spectral","fire"]:
			soundtrack.play_movement(units[id].sprite,true)
		await pause_animation(0.45)
		await turn_unit(id,destination.facing)
	else:
		var walked_seconds=0.0
		for step in route.slice(1):
			if units[id].large and step.facing!=units[id].facing:
				await turn_unit(id,step.facing)
				if step.head==units[id].pos: continue
			var start: Vector2=units[id].visual
			var finish=unit_center(id,step.head,step.facing)
			if not units[id].large:
				await turn_unit(id,1 if finish.x>=start.x else -1)
			var duration=0.18 if units[id].sprite in [7,9] else (0.32 if units[id].sprite==5 else 0.24)
			set_animation(id,"walk",duration)
			await tween_motion(duration,func(t):
				movement_sound_tick(id,walked_seconds+t*duration)
				units[id].visual=start.lerp(finish,t)
			)
			walked_seconds+=duration
			units[id].pos=step.head
			if units[id].large: units[id].facing=step.facing
	set_animation(id,"idle")
	units[id].visual=unit_center(id)
	moving_plan={}
	moving_id=-1

func receive_hit(id: int, direction: Vector2):
	if units[id].total<=0:
		for bound in units:
			if bound.get("bound_by",-1)==id: bound.rooted=false; bound.bound_by=-1
	units[id].flash=0.5
	var lethal=units[id].total<=0
	var duration=0.68 if lethal else 0.36
	set_animation(id,"death" if lethal else "hit",duration)
	await tween_motion(duration,func(t):
		if lethal:
			units[id].death_angle=0.0
			units[id].recoil=Vector2(direction.x*12*t,7*t)
		else:
			units[id].recoil=direction*10*sin(PI*t)
	)
	if not lethal:
		units[id].recoil=Vector2.ZERO
		set_animation(id,"idle")

func perform_attack(a: int,b: int, ranged: bool, retaliation: bool = false, followup: bool = false):
	units[a].attack_target=b
	if units[a].total<=0 or units[b].total<=0: return
	if not ranged and not touches(a,b,units[a].pos): return
	if ranged and not can_shoot(a): return
	await face_target(a,b)
	var from: Vector2=units[a].visual
	var to: Vector2=units[b].visual
	var direction=(to-from).normalized()
	if not retaliation and not followup:
		if ranged and units[a].sprite in Catalog.DOUBLE_SHOT: floating("DOUBLE SHOT",from-Vector2(0,135),BLUE)
		elif units[a].sprite==2: floating("DOUBLE STRIKE",from-Vector2(0,135),BLUE)
	elif retaliation and units[a].sprite==3:
		floating("RETALIATE",from-Vector2(0,135),BLUE)
	var duration=0.68 if ranged else (0.76 if units[a].sprite in [2,7] else 0.60)
	set_animation(a,"shoot" if ranged else "attack",duration)
	if ranged and units[a].sprite in Catalog.MAGIC_SHOT:
		effects.append({"kind":"charge","from":from-Vector2(0,55),"t":0.0,"life":duration*0.38,"color":projectile_color(units[a].sprite)})
	# Anticipation before release/contact. Damage is not applied during wind-up.
	await pause_animation(duration*0.38)
	if ranged:
		units[a].shots-=1
		var travel=clampf(from.distance_to(to)/1400.0,0.18,0.50)
		effects.append({"kind":"bolt","creature":units[a].sprite,"from":from-Vector2(0,49),"to":to-Vector2(0,49),"t":0.0,"life":travel,"magic":units[a].sprite in Catalog.MAGIC_SHOT,"color":projectile_color(units[a].sprite)})
		soundtrack.attack_release(units[a].sprite,true)
		await pause_animation(travel)
	else:
		soundtrack.attack_release(units[a].sprite,false)
		await tween_motion(0.12,func(t): units[a].recoil=direction*lerpf(-4,20,t))
		effects.append({"kind":"slash","from":to-Vector2(0,40),"to":to,"t":0.0,"life":0.32,"direction":direction,"color":Color("ffedc0")})
	var dr=damage_range(units[a],units[b],ranged,{},retaliation)
	var tags=attack_labels(units[a],units[b],ranged,{},retaliation)
	if not tags.is_empty(): floating(tags,from-Vector2(0,140),BLUE if units[a].side==0 else RED)
	var lucky=rng.randf()<maxi(0,luck(units[a]))/24.0
	if lucky:
		dr=damage_range(units[a],units[b],ranged,{},retaliation,true)
		proc_feedback("luck",a)
		effects.append({"kind":"critical","from":to-Vector2(0,48),"t":0.0,"life":.60})
	var damage=rng.randi_range(dr.x,dr.y)
	if units[a].sprite==7 and rng.randf()<0.2:
		damage*=2
		floating("DEATH BLOW",from-Vector2(0,150),GOLD)
		ability_feedback("death_blow",a,b)
	var actual_damage=mini(units[b].total,damage)
	units[b].wake_blind=units[b].get("blind_rounds",0)>0
	units[b].blind_rounds=0
	var before=amount(units[b])
	var before_total: int=units[b].total
	units[b].total=maxi(0,units[b].total-damage)
	receive_hit(b,direction)
	if units[a].sprite==12 and units[b].living and units[a].total>0:
		var healed=mini(units[a].max_total-units[a].total,actual_damage)
		units[a].total+=healed
		if healed>0:
			floating("DRAIN +%d"%healed,from-Vector2(0,105),Color("84bd95"))
			ability_feedback("drain",b,a)
	if not ranged and units[a].sprite==5 and units[b].living and units[b].total>0 and rng.randf()<0.2:
		units[b].diseased=true
		units[b].disease_rounds=3
		floating("DISEASE -2 ATK/DEF",to-Vector2(0,140),RED)
		ability_feedback("disease",a,b)
	if not ranged and units[a].sprite==18 and units[b].total>0:
		units[b].rooted=true
		units[b].bound_by=a
		floating("ROOTED",to-Vector2(0,130),Color("59824c"))
		ability_feedback("root",a,b)
	if not ranged and units[b].sprite==33 and units[a].sprite!=33:
		var reflected=maxi(1,actual_damage/5)
		var reflected_before: int=units[a].total
		units[a].total=maxi(0,units[a].total-reflected)
		hit_feedback(a,reflected_before,reflected)
		receive_hit(a,-direction)
		floating("FIRE SHIELD",from-Vector2(0,150),Color("ed914f"))
		ability_feedback("fire",b,a)
	if ranged and units[a].sprite==6:
		effects.append({"kind":"cloud","from":to,"to":to,"t":0.0,"life":0.85,"color":Color("9d78bb")})
		var affected: Array[int]=[b]
		for n in perimeter(b):
			var splash=occupant(n)
			if splash>=0 and splash!=a and not affected.has(splash) and units[splash].living:
				affected.append(splash)
				var splash_damage=damage
				var splash_before: int=units[splash].total
				units[splash].total=maxi(0,units[splash].total-splash_damage)
				receive_hit(splash,direction)
				hit_feedback(splash,splash_before,splash_damage)
				log_line("Death cloud engulfs %s for %d damage." % [units[splash].name,splash_damage])
	apply_creature_effects(a,b,ranged,damage)
	hit_feedback(b,before_total,damage)
	log_line("%s %s %s: %d damage · %d perish." % [units[a].name,"retaliate against" if retaliation else ("shoot" if ranged else "strike"),units[b].name,damage,before-amount(units[b])])
	soundtrack.attack_impact(units[a].sprite,units[b].sprite,ranged)
	if lucky: await get_tree().create_timer(.10).timeout
	effects.append({"kind":"impact","from":to-Vector2(0,55),"t":0.0,"life":0.38,"color":Color("ae82c0") if units[a].sprite==6 else Color("f6e2a9"),"claw":units[a].sprite in [3,5,11,12,13]})
	# Both the attacker recovery and defender's hit/death pose complete before
	# another strike, retaliation or the next creature is allowed to begin.
	var recovery=0.72 if units[b].total<=0 else 0.40
	await tween_motion(recovery,func(t): units[a].recoil=direction*20*(1-t) if not ranged else Vector2.ZERO)
	units[a].recoil=Vector2.ZERO
	set_animation(a,"idle")
	if not ranged and not retaliation and not followup and units[a].sprite not in Catalog.NO_RETALIATION and units[b].total>0 and units[b].get("blind_rounds",0)==0 and (not units[b].retaliated or units[b].sprite==3):
		units[b].retaliated=true
		await perform_attack(b,a,false,true)
	units[b].wake_blind=false
	# Retain the attack direction; do not flip back after each strike.

func act(target: Vector2i):
	if busy or ended or current<0: return
	var other = occupant(target)
	busy = true
	if other>=0 and units[other].side!=units[current].side:
		var ranged = can_shoot(current)
		var plan = approach(current,other,{},units[current].side==player_side and not auto_on)
		var dest: Vector2i = plan.head if not plan.is_empty() else Vector2i(-1,-1)
		if not ranged and dest.x<0:
			busy=false
			return
		if not ranged: await move_unit(current,dest,plan)
		await perform_attack(current,other,ranged)
		# Marksmen and crusaders strike twice; retaliation occurs only after first blow.
		if (units[current].sprite==2 or (units[current].sprite in Catalog.DOUBLE_SHOT and ranged)) and units[current].total>0 and units[other].total>0 and (not ranged or units[current].shots>0):
			await perform_attack(current,other,ranged,false,true)
	elif other==-1 and reachable.has(target):
		await move_unit(current,target)
		play_tone(180,0.06)
	else:
		busy=false
		return
	if not check_end():
		if units[current].total>0 and not units[current].get("morale_round",0)==round_no and rng.randf()<maxi(0,morale(units[current]))/24.0:
			units[current].morale_round=round_no
			proc_feedback("morale",current)
			await get_tree().create_timer(.65).timeout
			log_line("High morale! %s act again." % units[current].name)
			order.push_front(current)
		next_turn()

func ai_turn():
	if opening_battle: return
	if choosing_faction or ended or current<0 or ai_preview: return
	if units[current].side==player_side and not auto_on:
		busy=false
		return
	busy=false
	var enemies: Array[int] = []
	for i in range(units.size()):
		if units[i].total>0 and units[i].side!=units[current].side: enemies.append(i)
	if enemies.is_empty(): check_end(); return
	var best = enemies[0]
	var score = -INF
	for id in enemies:
		var dist = units[current].visual.distance_to(units[id].visual)
		var value = 1000.0-dist
		if can_shoot(current) or attack_cell(current,id).x>=0: value+=2000
		value+=100.0/amount(units[id])
		if value>score:
			score=value
			best=id
	if can_shoot(current) or attack_cell(current,best).x>=0:
		var plan={} if can_shoot(current) else approach(current,best)
		await preview_ai_action(plan,best)
		await act(units[best].pos)
		return
	var dest: Vector2i = units[current].pos
	var distance = INF
	var all_paths = paths(current,true)
	# Choose a reachable cell closest by BFS path length to an enemy-adjacent cell.
	var goals: Array[Vector2i] = []
	var destination_plan=approach(current,best,all_paths)
	if not destination_plan.is_empty(): goals.append(destination_plan.head)
	var move_plan={}
	if not goals.is_empty():
		for step in destination_plan.route:
			if step.cost>speed(units[current]): break
			if can_place(current,step.head,step.facing):
				dest=step.head
				move_plan={"route":destination_plan.route.slice(0,destination_plan.route.find(step)+1),"facing":step.facing,"cost":step.cost}
	else:
		for p in reachable:
			var d=unit_center(current,p,reachable[p].facing).distance_to(units[best].visual)
			if d<distance:
				distance=d
				dest=p
				move_plan=reachable[p]

	await preview_ai_action(move_plan,-1)
	if dest==units[current].pos:
		guard()
	else:
		busy=true
		await move_unit(current,dest,move_plan)
		next_turn()

func preview_ai_action(plan: Dictionary,target: int):
	busy=true
	ai_preview=true
	ai_plan={}
	ai_target=-1
	ai_phase="SELECT UNIT"
	await pause_animation(0.35)
	ai_plan=plan
	ai_phase="PLAN MOVE" if not plan.is_empty() else "HOLD POSITION"
	if not plan.is_empty(): await pause_animation(0.55)
	if target>=0:
		ai_target=target
		ai_phase="AIM SHOT" if can_shoot(current) else "SELECT ATTACK"
		await pause_animation(0.55)
	else:
		await pause_animation(0.25)
	ai_preview=false
	ai_plan={}
	ai_target=-1
	ai_phase=""
	busy=false

func guard():
	if opening_battle: return
	if current<0 or ended: return
	units[current].guard=true
	log_line("%s defend. Defense increased by 20%%." % units[current].name)
	next_turn()

func wait_action():
	if busy or current<0 or ended: return
	if units[current].get("wait_round",0)==round_no:
		guard()
		return
	units[current].wait_round=round_no
	waiting.append(current)
	log_line("%s wait for an opening." % units[current].name)
	next_turn()

func hit_feedback(id: int, previous_total: int, requested_damage: int):
	var lost=ceili(float(previous_total)/units[id].hp)-amount(units[id])
	var dealt=mini(previous_total,requested_damage)
	floating_tokens([["damage",str(dealt)],["fallen",str(maxi(0,lost))]],units[id].visual-Vector2(0,105),Color("fff1ce"))

func floating(value: String,p: Vector2,_color: Color):
	var codes={"BLIND":"blind","CURSE":"curse","DEATH BLOW":"death_blow","HATE":"hate","BREATH":"breath","TRIPLE":"triple","BRACED":"guard","DOUBLE SHOT":"double_shot","DOUBLE STRIKE":"double_strike","RETALIATE":"retaliation","FLANK":"flank","CHARGE":"charge","DISEASE":"disease","DISEASED":"disease","ROOTED":"root","FIRE SHIELD":"fire","DEATH CLOUD":"cloud","LONG RANGE":"range","SMITE":"smite","ETHEREAL":"ethereal","NO RETALIATION":"no_retaliation","LIFE DRAIN":"heal","DRAIN":"heal","LUCK":"luck","HIGH MORALE":"morale","LOW MORALE":"morale"}
	for line in value.split(" · "):
		var key="damage"
		var number=line.trim_prefix("−")
		for label in codes:
			if line==label or line.begins_with(label+" "):
				key=codes[label]
				number=line.trim_prefix(label).strip_edges().replace(" ATK/DEF","").replace("-","−")
				break
		var ink=Color("fff1ce") if key=="damage" else Color("9edfff")
		if key=="heal": ink=Color("a8f0b3")
		elif key in ["luck","morale"]: ink=Color("ffe08a")
		elif key=="fire": ink=Color("ffc08a")
		elif key in ["disease","root","blind","curse","range","ethereal"]: ink=Color("edb7ff")
		floating_tokens([[key,number]],p,ink)

func floating_tokens(tokens: Array,p: Vector2,ink: Color):
	var width=12.0
	for token in tokens: width+=34+number_font.get_string_size(token[1],HORIZONTAL_ALIGNMENT_LEFT,-1,26).x+12
	var pos=Vector2(clampf(p.x,28+width/2,1412-width/2),maxf(155,p.y))
	for attempt in range(16):
		var overlaps=false
		for other in effects:
			if other.kind!="text": continue
			var other_pos=other.from-Vector2(0,26*other.t/other.life)
			if absf(other_pos.x-pos.x)<(width+other.get("width",100.0))/2+12 and absf(other_pos.y-pos.y)<44:
				overlaps=true
				break
		if not overlaps: break
		pos.y-=46
		if pos.y<146: pos.y=maxf(155,p.y)+46*(attempt+1)
	effects.append({"kind":"text","tokens":tokens,"from":pos,"t":0.0,"life":2.0,"color":ink,"width":width})

func log_line(value: String):
	logs.append(value)
	if logs.size()>50: logs.pop_front()

func play_tone(frequency: float,duration: float):
	if self_test or DisplayServer.get_name()=="headless": return
	var stream = AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	var bytes = PackedByteArray()
	bytes.resize(int(22050*duration)*2)
	for i in range(bytes.size()/2):
		var envelope = pow(1.0-float(i)/(bytes.size()/2),2)
		var sample = sin(float(i)*frequency*TAU/22050.0)*envelope*0.16
		bytes.encode_s16(i*2,int(sample*32767))
	stream.data=bytes
	audio.stream=stream
	audio.play()

func _process(delta):
	clock+=delta
	for i in range(units.size()):
		var u=units[i]
		u.flash=maxf(0,u.flash-delta*animation_speed)
		u.anim_time+=delta*animation_speed
		var actor=actors[i]
		if actor.material:
			actor.material.set_shader_parameter("highlighted",(i==inspected or i==current) and not choosing_faction and not opening_battle and not ended and detail_id<0 and u.total>0)
			actor.material.set_shader_parameter("highlight_color",Color("ffe28a") if i==current else (Color("8ad9dc") if u.side==player_side else Color("f2ae82")))
		actor.visible=not choosing_faction and sprites.size()==Catalog.DATA.size()
		actor.position=u.visual+u.recoil+Vector2(0,8-u.lift)
		# Large creatures fill their two-hex footprint without stretching the painting.
		var body_scale=0.90 if u.sprite in [3,10] else (0.84 if u.large else 0.60)
		actor.scale=Vector2(u.facing*u.turn_scale,1.0)*body_scale
		actor.rotation=0.0
		actor.z_index=int(u.visual.y)+(500 if u.lift>0 else 0)
		actor.modulate=Color(1,1,1,maxf(0.0,1.0-u.anim_time/maxf(u.anim_duration,0.01))) if u.total<=0 else Color.WHITE
		actor.modulate.a*=u.get("phase_alpha",1.0)
		if sprites.size()==Catalog.DATA.size(): actor.update_pose(u.anim,u.anim_time,u.anim_duration,u.flash)
		if u.anim=="walk" and u.sprite in [7,9]:
			actor.position.y-=abs(sin(u.anim_time*18))*2.5
	if not choosing_faction and not opening_battle and not ended and detail_id<0: inspected=pick_action_target(get_global_mouse_position())
	update_action_cursor()
	update_badge_layout()
	for e in effects: e.t+=delta if e.kind in ["text","proc","critical"] else delta*animation_speed
	effects=effects.filter(func(e): return e.t<e.life)
	queue_redraw()
	if effects_layer: effects_layer.queue_redraw()
	if self_test and round_no>100:
		push_error("Self-test exceeded round limit")
		get_tree().quit(1)

func _unhandled_input(event):
	if ended:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and Rect2(610,490,220,52).has_point(event.position): button_action("restart")
		elif event is InputEventKey and event.pressed and event.keycode==KEY_R: button_action("restart")
		return
	if opening_battle: return
	if event is InputEventMouseButton and event.pressed and Rect2(88,8,1240,94).has_point(event.position) and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		initiative_offset=clampi(initiative_offset+(1 if event.button_index==MOUSE_BUTTON_WHEEL_DOWN else -1),0,maxi(0,initiative_preview().size()-12))
		queue_redraw()
		return
	if choosing_faction:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			for id in range(4):
				if map_card(id).has_point(event.position):
					select_map(id)
					return
			for side in range(Catalog.NAMES.size()):
				if faction_card(side).has_point(event.position): choose_faction(side)
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode==KEY_LEFT: select_map((map_id+3)%4)
			elif event.keycode==KEY_RIGHT: select_map((map_id+1)%4)
			elif event.keycode==KEY_1: choose_faction(0)
			elif event.keycode in [KEY_2,KEY_3,KEY_4,KEY_5]: choose_faction(event.keycode-KEY_1)
		return
	if detail_id>=0:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
			detail_id=-1
		if event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_RIGHT or Rect2(965,176,40,40).has_point(event.position) or not Rect2(420,160,600,552).has_point(event.position):
				detail_id=-1
			elif event.button_index==MOUSE_BUTTON_LEFT and Rect2(610,643,220,48).has_point(event.position) and can_detail_attack():
				var target=detail_target
				detail_id=-1
				act(target)
		return
	if event is InputEventMouseMotion:
		hovered=mouse_cell(event.position)
		inspected=pick_action_target(event.position)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			var id=pick_creature(event.position)
			if id>=0: open_creature_details(id,mouse_cell(event.position))
			return
		if event.button_index==MOUSE_BUTTON_LEFT:
			hovered=mouse_cell(event.position)
			for key in buttons:
				if buttons[key].has_point(event.position):
					button_action(key)
					return
			if settings_open:
				settings_open=false
				return
			if Rect2(22,774,280,76).has_point(event.position) and current>=0:
				open_creature_details(current,units[current].pos)
				return
			var queue=initiative_preview()
			for j in range(mini(12,queue.size()-initiative_offset)):
				if Rect2(88+j*96+initiative_slide,13,90,80).has_point(event.position):
					var queued=queue[j+initiative_offset]
					open_creature_details(queued,units[queued].pos)
					return
			var id=pick_action_target(event.position)
			if id>=0:
				if id==current and not busy and units[id].side==player_side:
					detail_id=-1
					reachable=paths(id)
				elif current>=0 and units[id].side!=player_side:
					if not busy and not auto_on and units[current].side==player_side and (can_shoot(current) or attack_cell(current,id).x>=0):
						act(units[id].pos)
				else: open_creature_details(id,hovered)
			elif valid(hovered): act(hovered)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B: soundtrack.toggle_music()
			KEY_M: AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
			KEY_G: grid_on=not grid_on
			KEY_S: animation_speed=2.0 if animation_speed==1.0 else 1.0
			KEY_W: wait_action()
			KEY_D:
				if not busy: guard()
			KEY_A:
				auto_on=not auto_on
				if auto_on and not busy: ai_turn()
			KEY_R: get_tree().reload_current_scene()
			KEY_ESCAPE:
				settings_open=false

func button_action(key: String):
	if opening_battle or (ended and key!="restart"): return
	match key:
		"settings": settings_open=not settings_open
		"mute": AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
		"music": soundtrack.toggle_music()
		"restart": get_tree().reload_current_scene()
		"speed": animation_speed=2.0 if animation_speed==1.0 else 1.0
		"grid": grid_on=not grid_on
		"auto":
			auto_on=not auto_on
			if auto_on and not busy: ai_turn()
		"wait": wait_action()
		"defend":
			if not busy: guard()

func mouse_cell(pos: Vector2) -> Vector2i:
	for y in range(ROWS):
		for x in range(COLS):
			var p=Vector2i(x,y)
			if Geometry2D.is_point_in_polygon(pos,hex_points(p)): return p
	return Vector2i(-1,-1)

func rect(r: Rect2,color: Color,border: Color=Color.TRANSPARENT):
	draw_rect(r,color)
	if border.a>0: draw_rect(r,border,false,1.0)

func text_at(value: String,p: Vector2,size: int=18,color: Color=IVORY,f: Font=null,canvas: Node2D=null):
	if canvas==null: canvas=self
	canvas.draw_string(font if f==null else f,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func center_text(value: String,p: Vector2,size: int=18,color: Color=IVORY,f: Font=null,canvas: Node2D=null):
	var use_font = font if f==null else f
	text_at(value,p-Vector2(use_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),size,color,use_font,canvas)

func panel(r: Rect2):
	var box=StyleBoxFlat.new()
	box.bg_color=Color("eadbb4")
	box.border_color=Color("9b7848")
	box.set_border_width_all(2)
	box.set_corner_radius_all(9)
	draw_style_box(box,r)
	draw_rect(r.grow(-5),Color("c8ad78"),false,1)

func ui_icon(index: int,r: Rect2,disabled: bool=false):
	if index<ui_icons.size():
		draw_texture_rect(ui_icons[index],r,false,Color(1,1,1,0.35 if disabled else 1.0))

func portrait(id: int,r: Rect2):
	if id<0 or id>=actors.size(): return
	var tex: Texture2D=actors[id].idle_frame
	if tex: draw_texture_rect(tex,r,false)

func button(key: String,r: Rect2,label: String,shortcut: String,active: bool=false,disabled: bool=false):
	if ended and not (key=="restart" and r.position.y==490): return
	if not disabled: buttons[key]=r
	var hover=not disabled and not opening_battle and r.has_point(get_global_mouse_position())
	var box=StyleBoxFlat.new()
	box.bg_color=Color("c5d2bb") if active else (Color("fff0c9") if hover else Color("dfcba1"))
	box.border_color=GOLD if hover or active else Color("b49a6b")
	box.set_border_width_all(3 if active else 1)
	box.set_corner_radius_all(10)
	draw_style_box(box,r)
	var index=ICON_KEYS.find(key)
	if index>=0:
		var icon_size=minf(r.size.x,r.size.y)-6
		ui_icon(ACTION_ICON_INDICES[index],Rect2(r.get_center()-Vector2.ONE*icon_size/2,Vector2.ONE*icon_size),disabled)
		if hover: ui_hint=ICON_HINTS[index]+(" · Unavailable" if disabled else "")
	elif key in ["settings","music","mute"]:
		var c=r.get_center()
		if key=="settings":
			var gear=PackedVector2Array()
			for j in range(48):
				var radius=22.0 if j%4 in [1,2] else 17.0
				gear.append(c+Vector2.from_angle(j*TAU/48)*radius)
			draw_colored_polygon(gear,Color("ba9253"))
			gear.append(gear[0])
			draw_polyline(gear,IVORY,2,true)
			draw_circle(c,8,Color("eadbb4"))
			draw_arc(c,8,0,TAU,24,IVORY,2,true)
			if hover: ui_hint="Settings"
		elif key=="music":
			draw_line(c+Vector2(-8,10),c+Vector2(-8,-13),IVORY,3,true)
			draw_line(c+Vector2(10,6),c+Vector2(10,-17),IVORY,3,true)
			draw_line(c+Vector2(-8,-13),c+Vector2(10,-17),IVORY,5,true)
			draw_circle(c+Vector2(-12,11),6,IVORY)
			draw_circle(c+Vector2(6,7),6,IVORY)
			if not soundtrack.music_enabled: draw_line(c-Vector2(19,19),c+Vector2(19,19),RED,3,true)
			if hover: ui_hint="Music: %s · B" % ("On" if soundtrack.music_enabled else "Off")
		else:
			draw_colored_polygon(PackedVector2Array([c+Vector2(-17,-6),c+Vector2(-8,-6),c+Vector2(3,-16),c+Vector2(3,16),c+Vector2(-8,6),c+Vector2(-17,6)]),IVORY)
			draw_arc(c+Vector2(2,0),17,-0.8,0.8,16,IVORY,3,true)
			if AudioServer.is_bus_mute(0): draw_line(c-Vector2(19,19),c+Vector2(19,19),RED,3,true)
			if hover: ui_hint="Mute all audio · M"
	else: center_text(label,r.get_center()+Vector2(0,6),16)
	if key=="speed": center_text("2×" if animation_speed>1 else "1×",r.end-Vector2(13,7),12)

func _draw():
	buttons.clear()
	ui_hint=""
	draw_background()
	if choosing_faction:
		draw_faction_picker()
		return
	for y in range(ROWS):
		for x in range(COLS):
			var p=Vector2i(x,y)
			var poly=hex_points(p)
			if not busy and not ended and reachable.has(p) and occupant(p)<0:
				draw_colored_polygon(poly,Color(0.18,0.53,0.67,0.32))
				var edge=poly.duplicate()
				edge.append(edge[0])
				draw_polyline(edge,Color("8bc9cd"),2,true)
			if grid_on:
				var line=poly.duplicate()
				line.append(poly[0])
				draw_polyline(line,Color("f4e7b7"),3,true)
				draw_polyline(line,Color(0.28,0.28,0.15,0.68),1.4,true)
			if p==hovered:
				draw_colored_polygon(poly,Color(0.91,0.8,0.43,0.2))
				var line=poly.duplicate()
				line.append(poly[0])
				draw_polyline(line,GOLD,2,true)
	if not busy and not ended and current>=0 and reachable.has(hovered) and occupant(hovered)<0:
		for cell in footprint(current,hovered,reachable[hovered].facing):
			draw_colored_polygon(hex_points(cell,3),Color(GOLD,0.28))
	draw_path_preview()
	for p in obstacles: draw_rock(cell_center(p))
	var sorted: Array[int]=[]
	for i in range(units.size()): sorted.append(i)
	sorted.sort_custom(func(a,b): return units[a].visual.y<units[b].visual.y)
	for id in sorted:
		if units[id].total<=0: draw_corpse(units[id])
	for id in sorted:
		if units[id].total>0: draw_unit(id)
	draw_interface()
	if ended: draw_end()

func draw_background():
	rect(Rect2(0,0,1440,872),Color("c7af81"))
	if background:
		draw_texture_rect(background,Rect2(8,108,1424,646),false)
	else:
		rect(Rect2(8,108,1424,646),Color("647050"))
		for i in range(80):
			var x = fmod(i*173.23,1440)
			var y = 230+fmod(i*117.34,510)
			draw_circle(Vector2(x,y),20+fmod(i*17.1,50),Color(0.3,0.33,0.2,0.12))
	draw_line(Vector2(8,108),Vector2(1432,108),GOLD,2)
	draw_line(Vector2(8,754),Vector2(1432,754),GOLD,2)

func draw_rock(p: Vector2):
	draw_set_transform(p)
	paint_ellipse(Vector2(0,8),Vector2(31,10),Color(0,0,0,0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-29,5),Vector2(-24,-17),Vector2(-4,-28),Vector2(21,-17),Vector2(29,7)]),Color("686953"))
	draw_colored_polygon(PackedVector2Array([Vector2(-24,-17),Vector2(-4,-28),Vector2(21,-17),Vector2(2,-10)]),Color("96917a"))
	draw_line(Vector2(2,-10),Vector2(10,5),Color("444b40"),2)
	draw_set_transform(Vector2.ZERO)

func paint_ellipse(p: Vector2,s: Vector2,c: Color):
	var points=PackedVector2Array()
	for j in range(32): points.append(p+Vector2(cos(j*TAU/32)*s.x,sin(j*TAU/32)*s.y))
	draw_colored_polygon(points,c)

func draw_corpse(u: Dictionary):
	var p: Vector2=u.visual
	paint_ellipse(p,Vector2(37 if u.large else 22,8),Color(0.12,0.10,0.08,0.4))
	draw_line(p+Vector2(-12,-3),p+Vector2(12,2),Color("98917d"),4)
	draw_line(p+Vector2(-3,-8),p+Vector2(5,7),Color("98917d"),3)

func draw_unit(id: int):
	var u=units[id]
	var p: Vector2=u.visual
	var selected=id==current
	var team = BLUE if u.side==0 else RED
	var moving=u.anim in ["walk","fly","land"]
	if selected and not moving:
		for cell in footprint(id):
			var poly=hex_points(cell,3)
			draw_colored_polygon(poly,Color(team,0.22))
			poly.append(poly[0])
			draw_polyline(poly,Color("ecd78a"),2,true)
	# Moving units have neither a ground oval nor a selected-footprint marker.
	if not moving:
		paint_ellipse(p+Vector2(0,5),Vector2(52 if u.large else 20,8 if u.large else 7),Color(0.04,0.04,0.025,0.25))

func badge_body_rect(id: int) -> Rect2:
	var u=units[id]
	var scale_value=absf(actors[id].scale.y)
	var height=UnitPose.STORY_HEIGHTS[u.sprite]*scale_value
	var width=(150.0 if u.large else 85.0)*scale_value
	return Rect2(actors[id].position-Vector2(width/2,height-8),Vector2(width,height))

func update_badge_layout():
	badge_rects.clear()
	var bodies={}
	for id in range(units.size()):
		if units[id].total>0: bodies[id]=badge_body_rect(id)
	for id in bodies:
		var u=units[id]
		var side=1.0 if u.side==0 else -1.0
		var width=maxf(28,font.get_string_size(str(amount(u)),HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+10)
		var best=Rect2()
		var best_score=INF
		# Prefer a compact label just in front of the feet; move only to avoid bodies.
		for flip in [1.0,-1.0]:
			for extra in [0.0,20.0,40.0,60.0]:
				for dy in [0.0,20.0,-20.0,40.0]:
					var center=u.visual+Vector2(side*flip*((76.0 if u.large else 43.0)+extra),dy)
					var r=Rect2(center-Vector2(width/2,8),Vector2(width,16))
					r.position.x=clampf(r.position.x,12,1428-width)
					r.position.y=clampf(r.position.y,112,736)
					var score=extra+absf(dy)*1.5+(45 if flip<0 else 0)
					for other in bodies:
						var overlap=r.intersection(bodies[other])
						if overlap.has_area(): score+=1000+overlap.get_area()*5
					for other in badge_rects:
						if r.grow(2).intersects(badge_rects[other]): score+=3000
					if score<best_score:
						best_score=score
						best=r
		badge_rects[id]=best

func draw_unit_badge(id: int, canvas: Node2D):
	var u=units[id]
	var p: Vector2=u.visual
	var badge: Rect2=badge_rects.get(id,Rect2(p+Vector2(35,-8),Vector2(28,16)))
	canvas.draw_rect(badge,Color("344859") if u.side==0 else Color("59415e"))
	canvas.draw_rect(badge,GOLD if id==current else (BLUE if u.side==0 else RED).darkened(0.3),false)
	center_text(str(amount(u)),badge.position+Vector2(badge.size.x/2,12),13,Color("fff0cd"),null,canvas)
	if u.guard: text_at("◆",p+Vector2(-30,18),17,BLUE,null,canvas)
	if u.get("diseased",false): text_at("-2",p+Vector2(-38,-49),15,RED,null,canvas)


const AbilityFeedback=preload("res://scripts/ability_feedback.gd")

func ability_feedback(skill: String, source: int, target: int):
	effects.append({"kind":"ability","skill":skill,"from":units[source].visual-Vector2(0,48),"to":units[target].visual-Vector2(0,48),"t":0.0,"life":0.85})
	soundtrack.play_ability(skill)

signal proc_triggered(cue: String, unit_id: int)

func proc_feedback(cue: String, id: int):
	proc_triggered.emit(cue,id)
	effects.append({"kind":"proc","cue":cue,"unit":id,"from":units[id].visual,"t":0.0,"life":2.0})
	soundtrack.play_proc(cue)

func draw_effects(canvas: Node2D):
	for e in effects:
		var t: float=e.t/e.life
		if e.kind=="proc":
			var alpha=1.0-smoothstep(.75,1.0,t)
			var tint=Color("9ee6aa") if e.cue=="luck" else (Color("ffd477") if e.cue=="morale" else Color("e39898"))
			var body=badge_body_rect(e.unit)
			var p=Vector2(body.get_center().x,body.position.y-36)
			var best_score=INF
			var anchor=p
			for offset in [Vector2.ZERO,Vector2(-70,0),Vector2(70,0),Vector2(0,-65),Vector2(-110,30),Vector2(110,30)]:
				var candidate=Vector2(clampf(anchor.x+offset.x,40,1400),clampf(anchor.y+offset.y,140,700))
				var r=Rect2(candidate-Vector2(30,30),Vector2(60,60))
				var score=offset.length()
				for id in range(units.size()):
					if units[id].total>0 and r.intersects(badge_body_rect(id)): score+=10000
				if score<best_score: best_score=score; p=candidate
			var size=52.0+6*sin(minf(t*8,1)*PI)
			var r=Rect2(p-Vector2.ONE*size/2,Vector2.ONE*size)
			var icon=combat_icons["luck" if e.cue=="luck" else "morale"]
			for off in [Vector2(-2,0),Vector2(2,0),Vector2(0,-2),Vector2(0,2)]:
				canvas.draw_texture_rect(icon,Rect2(r.position+off,r.size),false,Color(.17,.16,.12,.95*alpha))
			canvas.draw_texture_rect(icon,r,false,Color(tint,alpha))
			if e.cue=="panic": canvas.draw_line(r.position,r.end,Color(tint,alpha),3,true)
		elif e.kind=="critical":
			var p: Vector2=e.from
			var alpha=pow(1-t,1.4)
			# A brief solid core, then a hollow shock ring and ballistic sparks.
			if t<.22:
				var flash=1-t/.22
				var points=PackedVector2Array()
				for j in range(16):
					points.append(p+Vector2.from_angle(j*TAU/16)*((44 if j%2==0 else 12)*(1+t)))
				canvas.draw_colored_polygon(points,Color(1,.95,.7,flash))
			for j in range(12):
				var d=Vector2.from_angle(j*TAU/12+.15)
				var travel=1-pow(1-t,3)
				var start=p+d*(18+50*travel)+Vector2(0,24*t*t)
				var finish=start+d*((38 if j%2==0 else 21)*(1-t))
				canvas.draw_line(start,finish,Color(1,.55,.12,alpha),7*(1-t)+1,true)
				canvas.draw_line(start,finish,Color(1,.98,.82,alpha),3*(1-t)+1,true)
			canvas.draw_arc(p,18+78*(1-pow(1-t,3)),0,TAU,48,Color(1,.82,.3,alpha*.8),5*(1-t)+1,true)
		elif e.kind=="fortune":
			for j in range(5):
				canvas.draw_arc(e.from,22+j*6,-PI,0,32,Color(["edb66e","e6ce80","a8bd83","8dbcc4","b19bc7"][j],1-t),4,true)
		elif e.kind=="ability":
			AbilityFeedback.draw(canvas,e)
		elif e.kind=="text":
			var alpha=1.0-smoothstep(0.72,1.0,t)
			var pos: Vector2=e.from+Vector2(-e.width/2,-26*t)
			var panel_style=StyleBoxFlat.new()
			panel_style.bg_color=Color(0.13,0.10,0.15,0.92*alpha)
			panel_style.border_color=Color(0.71,0.57,0.34,0.8*alpha)
			panel_style.set_border_width_all(1)
			panel_style.set_corner_radius_all(6)
			canvas.draw_style_box(panel_style,Rect2(pos-Vector2(0,30),Vector2(e.width,40)))
			var x=pos.x+8
			var center_y=pos.y-10
			var baseline=center_y+(number_font.get_ascent(26)-number_font.get_descent(26))/2
			for token in e.tokens:
				canvas.draw_texture_rect(combat_icons[token[0]],Rect2(Vector2(x,center_y-14),Vector2(28,28)),false,Color(e.color,alpha))
				x+=34
				canvas.draw_string(number_font,Vector2(x,baseline),token[1],HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color(e.color,alpha))
				x+=number_font.get_string_size(token[1],HORIZONTAL_ALIGNMENT_LEFT,-1,26).x+12
		elif e.kind=="bolt":
			var p: Vector2=e.from.lerp(e.to,t)
			var direction: Vector2=(e.to-e.from).normalized()
			var normal=direction.orthogonal()
			if e.get("creature",-1)==27:
				var arc=PackedVector2Array()
				for j in range(6):
					arc.append(p-direction*j*5+normal*(7 if j%2 else -7))
				canvas.draw_polyline(arc,Color("73c9ed"),6,true)
				canvas.draw_polyline(arc,Color("f5fdff"),2,true)
			elif e.get("magic",false):
				for j in range(6,0,-1):
					var tail=p-direction*j*5+normal*sin(t*18-j*0.55)*6
					canvas.draw_circle(tail,lerpf(2,13,1.0-j/7.0),Color(e.color,0.45*(1.0-j/7.0)))
				canvas.draw_circle(p,20,Color(e.color,0.13))
				canvas.draw_circle(p,12,e.color.darkened(0.25))
				canvas.draw_circle(p,7,e.color.lightened(0.55))
				canvas.draw_circle(p-direction*2,3,Color("fff6df"))
				for j in range(5):
					var spark=p+Vector2.from_angle(t*12+j*TAU/5)*18
					canvas.draw_line(spark-normal*3,spark+normal*3,Color("f0d8ff"),2,true)
			else:
				canvas.draw_line(p-direction*18,p,Color("68462e"),3,true)
				canvas.draw_colored_polygon(PackedVector2Array([p+direction*6,p-direction*5+normal*4,p-direction*5-normal*4]),Color("eee5ca"))
		elif e.kind=="charge":
			for j in range(7):
				var radius=28*(1-t)+4
				var p=e.from+Vector2.from_angle(j*TAU/7+t*5)*radius
				canvas.draw_circle(p,2+3*t,Color(e.color,0.5+0.5*t))
			canvas.draw_circle(e.from,4+7*t,Color("f1dfff")*Color(1,1,1,t))
		elif e.kind=="magic":
			var p: Vector2=e.from
			canvas.draw_line(p-Vector2(0,180),p,e.color,4*(1-t),true)
			canvas.draw_arc(p,15+45*t,0,TAU,40,Color(e.color,1-t),3,true)
			for j in range(8):
				var off=Vector2(cos(j*TAU/8+t*3),sin(j*TAU/8+t*3))*t*55
				canvas.draw_circle(p+off,3*(1-t),e.color)

		elif e.kind=="slash":
			var p: Vector2=e.from
			var facing=1.0 if e.get("direction",Vector2.RIGHT).x>=0 else -1.0
			var ribbon=PackedVector2Array()
			var edge=PackedVector2Array()
			for j in range(18):
				var angle=-1.9+float(j)/17*2.6+t*0.6
				var point=p+Vector2(cos(angle)*facing,sin(angle))*(48+t*18)
				ribbon.append(point)
				edge.append(point)
			for j in range(17,-1,-1):
				var angle=-1.9+float(j)/17*2.6+t*0.6
				ribbon.append(p+Vector2(cos(angle)*facing,sin(angle))*(30+t*26))
			canvas.draw_colored_polygon(ribbon,Color(e.color,0.75*(1-t)))
			canvas.draw_polyline(edge,Color("fff9e7")*Color(1,1,1,1-t),3,true)
		elif e.kind=="impact":
			var p: Vector2=e.from
			var burst=PackedVector2Array()
			for j in range(16):
				var radius=(34.0 if j%2==0 else 12.0)*(0.6+t)
				burst.append(p+Vector2.from_angle(j*TAU/16)*radius)
			canvas.draw_colored_polygon(burst,Color(e.color,0.85*(1-t)))
			burst.append(burst[0])
			canvas.draw_polyline(burst,Color("795238")*Color(1,1,1,1-t),2,true)
			for j in range(7):
				var dir=Vector2.from_angle(j*TAU/7+0.2)
				canvas.draw_line(p+dir*(25+45*t),p+dir*(35+52*t),Color(e.color,1-t),3*(1-t),true)
			if e.claw:
				for j in range(3):
					canvas.draw_line(p+Vector2(-22+j*12,-30),p+Vector2(-2+j*12,24),Color("fff1cf")*Color(1,1,1,1-t),4,true)
		elif e.kind=="cloud":
			for j in range(11):
				var off=Vector2(cos(j*2.3),sin(j*2.3))*t*62
				canvas.draw_circle(e.from+off-Vector2(0,25+12*t),10+15*t,Color(e.color,(1-t)*0.15))

func draw_interface():
	panel(Rect2(8,8,1424,94))
	ui_icon(0,Rect2(26,20,40,40))
	center_text(str(round_no),Vector2(46,83),20,GOLD)
	# Sliding upcoming queue, followed by a visibly separated next-round preview.
	var preview=initiative_preview()
	var boundary=(1 if current>=0 and units[current].total>0 else 0)
	for id in order+waiting:
		if units[id].total>0: boundary+=1
	for j in range(mini(12,preview.size()-initiative_offset)):
		var index=j+initiative_offset
		var id=preview[index]
		var u=units[id]
		var acting=index==0 and not ended
		var r=Rect2(88+j*96+initiative_slide,13,90,80)
		rect(r,Color("d7e2db") if u.side==0 else Color("e0cddd"),GOLD if acting else Color("b7a078"))
		portrait(id,r.grow(-3))
		if index>=boundary: draw_rect(r,Color(.8,.75,.65,.35))
		if acting: draw_rect(r.grow(2),GOLD,false,3)
		if index==boundary: draw_line(r.position-Vector2(4,0),r.position+Vector2(-4,76),GOLD,3)
		rect(Rect2(r.end-Vector2(30,20),Vector2(30,20)),Color("f4e6c5"))
		center_text(str(amount(u)),r.end-Vector2(15,5),13)
		if r.has_point(get_global_mouse_position()): ui_hint=u.name+(" · Acting now" if acting else (" · Next round" if index>=boundary else " · Upcoming"))+" · Scroll to browse"
	var bar_width=1152.0*minf(1,12.0/maxi(1,preview.size()))
	draw_line(Vector2(88,98),Vector2(1240,98),MUTED,2)
	draw_line(Vector2(88+initiative_offset*1152.0/maxi(1,preview.size()),98),Vector2(88+initiative_offset*1152.0/maxi(1,preview.size())+bar_width,98),GOLD,3)
	button("settings",Rect2(1352,22,58,58),"","",settings_open)
	# One row: unit summary | five combat actions | four utility controls.
	panel(Rect2(8,764,1424,100))
	var show_id=inspected if inspected>=0 and not busy else current
	if show_id>=0:
		var u=units[show_id]
		portrait(show_id,Rect2(22,774,76,76))
		text_at(u.name,Vector2(108,791),18)
		var hp=((u.total-1)%u.hp)+1 if u.total>0 else 0
		rect(Rect2(108,805,156,7),Color("c9b58d"))
		rect(Rect2(108,805,156.0*hp/u.hp,7),Color("739775"))
		text_at("×%d   HP %d/%d" % [amount(u),hp,u.hp],Vector2(108,838),15)
		if Rect2(22,774,280,76).has_point(get_global_mouse_position()):
			ui_hint="ATK %d · DEF %d · DMG %d–%d · SPD %d · Ammo %d\n%s" % [effective_attack(u),effective_defense(u),u.lo,u.hi,speed(u),u.shots,ABILITIES[u.sprite]]
	for i in range(2):
		button(ICON_KEYS[i],Rect2(650+i*78,784,64,60),"","",false,busy or ended)

	draw_line(Vector2(1080,786),Vector2(1080,842),Color("c8ad78"),1)
	for i in range(2,6):
		var active=animation_speed>1 if i==2 else (grid_on if i==3 else (auto_on if i==4 else false))
		button(ICON_KEYS[i],Rect2(1112+(i-2)*76,784,60,60),"","",active)

	if settings_open:
		panel(Rect2(1230,109,180,90))
		button("music",Rect2(1244,122,64,64),"","",soundtrack.music_enabled)
		button("mute",Rect2(1320,122,64,64),"","",AudioServer.is_bus_mute(0))
	if not ui_hint.is_empty() and not opening_battle and not ended:
		var hint_lines=ui_hint.split("\n")
		var width=0.0
		for line in hint_lines: width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+28)
		var height=hint_lines.size()*22+12
		var tip=Rect2(Vector2(clampf(get_global_mouse_position().x-width/2,16,1424-width),753-height),Vector2(width,height))
		panel(tip)
		for j in range(hint_lines.size()): center_text(hint_lines[j],tip.position+Vector2(width/2,23+j*22),16)

func draw_end():
	panel(Rect2(420,326,600,234))
	var won=false
	for u in units:
		if u.side==player_side and u.total>0: won=true
	center_text("VICTORY" if won else "DEFEAT",Vector2(720,391),43,GOLD,serif)
	center_text("Your army holds the valley." if won else "Your army has fallen.",Vector2(720,432),19,IVORY)
	center_text("Battle concluded in %d rounds" % round_no,Vector2(720,466),15,MUTED)
	button("restart",Rect2(610,490,220,52),"Fight again","R")

func capture_frame():
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/battle-preview.png")
	print("CAPTURE SAVED")

func draw_path_preview():
	if ended or current<0: return
	var plan={}
	var route_id=current
	if not moving_plan.is_empty():
		plan=moving_plan
		route_id=moving_id
	elif ai_preview:
		plan=ai_plan
		if ai_target>=0:
			for cell in footprint(ai_target):
				var poly=hex_points(cell,2)
				draw_colored_polygon(poly,Color(RED,0.22))
				poly.append(poly[0])
				draw_polyline(poly,RED,3,true)

	else:
		if busy or not valid(hovered): return
		var enemy=occupant(hovered)
		if enemy>=0:
			if units[enemy].side==units[current].side or can_shoot(current): return
			plan=approach(current,enemy,{},units[current].side==player_side and not auto_on)
		elif reachable.has(hovered): plan=reachable[hovered]
	if plan.is_empty(): return
	var route: Array=plan.route
	var painted={}
	for j in range(route.size()):
		for cell in footprint(route_id,route[j].head,route[j].facing):
			if painted.has(cell): continue
			painted[cell]=true
			var poly=hex_points(cell,4)
			draw_colored_polygon(poly,Color(0.30,0.57,0.66,0.25))
			poly.append(poly[0])
			draw_polyline(poly,Color("60949b"),2,true)
	for step in [route[0],route[-1]]:
		for cell in footprint(route_id,step.head,step.facing):
			var poly=hex_points(cell,3)
			draw_colored_polygon(poly,Color(0.96,0.83,0.43,0.3))
			poly.append(poly[0])
			draw_polyline(poly,Color("fff0b7"),3,true)

func validate_layout() -> bool:
	var occupied={}
	for id in range(units.size()):
		if units[id].total<=0: continue
		for cell in footprint(id):
			if not valid(cell) or obstacles.has(cell) or occupied.has(cell):
				push_error("Invalid footprint for %s at %s" % [units[id].name,cell])
				return false
			occupied[cell]=id
	return true

func faction_card(faction: int) -> Rect2:
	# Three compact cards above two centered cards.
	var row=faction/3
	var column=faction%3
	return Rect2((205 if row==0 else 380)+column*350,165+row*310,330,285)

func random_opponent(faction: int) -> int:
	var pick=opponent_rng.randi_range(0,Catalog.NAMES.size()-2)
	return pick+1 if pick>=faction else pick

func choose_faction(faction: int):
	if not choosing_faction or faction<0 or faction>=Catalog.NAMES.size(): return
	player_side=1 if faction==1 else 0
	var opponent=random_opponent(faction)
	army_factions=[faction,opponent] if player_side==0 else [opponent,faction]
	choosing_faction=false
	hovered=Vector2i(-1,-1)
	inspected=-1
	buttons.clear()
	soundtrack.set_battlefield(map_id)
	opening_battle=true
	new_battle()
	soundtrack.play_battle_start()
	get_tree().create_timer(5.0).timeout.connect(finish_battle_opening)
	queue_redraw()

func finish_battle_opening():
	if not opening_battle or ended: return
	opening_battle=false
	next_turn()
	queue_redraw()

func draw_faction_picker():
	draw_rect(Rect2(0,0,1440,872),Color(0.12,0.14,0.12,0.55))
	center_text("KINGDOMS",Vector2(720,77),40,Color("f7e7bf"),serif)
	center_text("CHOOSE YOUR FACTION",Vector2(720,119),17,Color("ecdbb6"))
	for faction in range(Catalog.NAMES.size()):
		var r=faction_card(faction)
		var hover=r.has_point(get_global_mouse_position())
		panel(r)
		var art=Rect2(r.position+Vector2(7,7),Vector2(316,196))
		if faction<faction_towns.size():
			var town=faction_towns[faction]
			var source_size=town.get_size()
			var ratio=art.size.x/art.size.y
			var crop=source_size
			if source_size.x/source_size.y>ratio: crop.x=source_size.y*ratio
			else: crop.y=source_size.x/ratio
			draw_texture_rect_region(town,art,Rect2((source_size-crop)/2,crop))
		center_text(Catalog.NAMES[faction],r.position+Vector2(165,229),21,Color(Catalog.COLORS[faction]),serif)
		var roster=Catalog.ROSTERS[faction]
		for j in range(7):
			var kind=roster[j]
			if kind<sprites.size(): draw_texture_rect(sprites[kind],Rect2(r.position+Vector2(9+j*45,241),Vector2(43,39)),false)
		draw_rect(r,GOLD if hover else Color("a58c63"),false,4 if hover else 2)
		if hover:
			center_text("PLAY  ·  RANDOM OPPONENT",Vector2(720,145),17,Color("fff0c9"))

	for id in range(4):
		var r=map_card(id)
		draw_texture_rect(map_textures[id],r,false)
		draw_rect(r,GOLD if id==map_id else Color("b49b72"),false,4 if id==map_id else 1)
		if id==map_id: center_text("✓",r.end-Vector2(14,8),20,Color("fff1c8"))
		if r.has_point(get_global_mouse_position()):
			center_text(Battlefields.NAMES[id],Vector2(720,770),16,Color("fff1c8"))

func projectile_color(kind: int) -> Color:
	if kind==6: return Color("c8a1ee")
	if kind in [24,27]: return Color("8bdafa")
	if kind==29: return Color("ff914d")
	return Color("ffe5a0")

func movement_sound_tick(id: int, elapsed: float):
	if elapsed+0.0001<movement_sound_clock: return
	soundtrack.play_movement(units[id].sprite)
	movement_sound_clock=elapsed+soundtrack.movement_interval(units[id].sprite)

func open_creature_details(id: int, cell: Vector2i):
	if opening_battle or ended: return
	detail_id=id
	detail_target=cell if cell in footprint(id) else units[id].pos
	settings_open=false
	queue_redraw()

func can_detail_attack() -> bool:
	if detail_id<0 or current<0 or busy or ended or auto_on or units[current].side!=player_side: return false
	if units[detail_id].side==units[current].side or units[detail_id].total<=0: return false
	return can_shoot(current) or attack_cell(current,detail_id).x>=0

func details_wrapped(value: String, position: Vector2, width: float, canvas: Node2D):
	var line=""
	var y=position.y
	for word in value.split(" "):
		var candidate=word if line.is_empty() else line+" "+word
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x>width and not line.is_empty():
			text_at(line,Vector2(position.x,y),17,IVORY,null,canvas)
			y+=24
			line=word
		else: line=candidate
	text_at(line,Vector2(position.x,y),17,IVORY,null,canvas)

func detail_icon(kind: String, box: Rect2, canvas: Node2D):
	if combat_icons.has(kind):
		canvas.draw_texture_rect(combat_icons[kind],box,false,Color("59432f"))
		return
	var c=box.get_center()
	var lookup={"attack":7,"defense":1,"speed":3,"guard":1,"root":6,"retaliation":8,"size":6}
	if lookup.has(kind):
		canvas.draw_texture_rect(ui_icons[lookup[kind]],box,false)
	elif kind=="ability":
		canvas.draw_rect(Rect2(c-Vector2(17,14),Vector2(34,28)),Color("f4e5bf"))
		canvas.draw_rect(Rect2(c-Vector2(17,14),Vector2(34,28)),GOLD,false,2)
		canvas.draw_line(c-Vector2(0,14),c+Vector2(0,14),GOLD,2)
		for j in range(3):
			canvas.draw_line(c+Vector2(-12,-7+j*7),c+Vector2(-4,-7+j*7),IVORY,1)
			canvas.draw_line(c+Vector2(4,-7+j*7),c+Vector2(12,-7+j*7),IVORY,1)
	elif kind=="damage":
		var burst=PackedVector2Array()
		for j in range(12): burst.append(c+Vector2.from_angle(j*TAU/12)*(19 if j%2==0 else 8))
		canvas.draw_colored_polygon(burst,GOLD)
		canvas.draw_line(c+Vector2(-7,8),c+Vector2(7,-8),IVORY,4,true)
	elif kind=="health":
		var points=PackedVector2Array([c+Vector2(0,15),c+Vector2(-17,-2),c+Vector2(-16,-11),c+Vector2(-8,-15),c+Vector2(0,-7),c+Vector2(8,-15),c+Vector2(16,-11),c+Vector2(17,-2)])
		canvas.draw_colored_polygon(points,Color("a76053"))
		points.append(points[0]);canvas.draw_polyline(points,GOLD,2,true)
	elif kind=="ammo":
		for j in range(3):
			var p=c+Vector2(-10+j*9,0)
			canvas.draw_line(p+Vector2(-8,13),p+Vector2(8,-13),IVORY,2,true)
			canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(10,-16),p+Vector2(1,-12),p+Vector2(8,-7)]),GOLD)
	else:
		canvas.draw_circle(c,15,Color("b49360"))
		center_text("!",c+Vector2(0,7),22,IVORY,null,canvas)

func draw_creature_details(canvas: Node2D):
	var u=units[detail_id]
	canvas.draw_rect(Rect2(0,108,1440,646),Color(0.12,0.10,0.08,0.45))
	canvas.draw_rect(Rect2(420,160,600,552),Color("efdfb7"))
	canvas.draw_rect(Rect2(420,160,600,552),GOLD,false,3)
	canvas.draw_texture_rect(sprites[u.sprite],Rect2(448,180,120,120),false)
	text_at(u.name,Vector2(588,204),25,IVORY,serif,canvas)
	canvas.draw_rect(Rect2(588,222,286,7),BLUE if u.side==player_side else RED)
	text_at("×%d"%amount(u),Vector2(588,260),27,IVORY,null,canvas)
	canvas.draw_texture_rect(faction_towns[army_factions[u.side]],Rect2(895,230,92,58),false)
	center_text("×",Vector2(985,205),28,IVORY,null,canvas)
	var hp=((u.total-1)%u.hp)+1 if u.total>0 else 0
	var kinds=["attack","defense","damage","speed","health","ammo"]
	var values=[str(effective_attack(u)),str(effective_defense(u)),"%d–%d"%[u.lo,u.hi],str(speed(u)),"%d/%d"%[hp,u.hp],str(u.shots)]
	var hints=["Attack (including hero and status effects)","Defense (including hero and status effects)","Damage per creature", "Movement range in hexes", "Top creature HP · Stack total %d / %d"%[u.total,u.max_total],"Remaining ranged shots"]
	var tooltip=""
	for j in range(6):
		var r=Rect2(450+(j%3)*182,310+(j/3)*84,172,74)
		canvas.draw_rect(r,Color("e1cda3"))
		detail_icon(kinds[j],Rect2(r.position+Vector2(8,12),Vector2(46,46)),canvas)
		center_text(values[j],r.position+Vector2(111,46),23,IVORY,null,canvas)
		if r.has_point(get_global_mouse_position()): tooltip=hints[j]
	for stat in range(2):
		var r=Rect2(620+stat*115,268,105,30)
		detail_icon("morale" if stat==0 else "luck",Rect2(r.position,Vector2(26,26)),canvas)
		text_at("%+d"%(morale(u) if stat==0 else luck(u)),r.position+Vector2(34,22),19,Color("594936"),null,canvas)
		if r.has_point(get_global_mouse_position()): tooltip="Morale: extra action / lost turn; undead and golems immune" if stat==0 else "Luck: Basic Luck +1; enemy Devil -1. Lucky attacks add 100% base damage."
	var badges=[]
	for key in ABILITY_ICONS[u.sprite]: badges.append([key,ABILITIES[u.sprite]])
	if u.flying: badges.append(["speed","Flying: crosses obstacles and units"])
	if u.large: badges.append(["size","Occupies two horizontal hexes"])
	if u.guard: badges.append(["guard","Defending +20%"])
	if u.diseased: badges.append(["disease","Disease -2 attack / defense"])
	if u.rooted: badges.append(["root","Bound: movement blocked until binder moves or dies"])
	if u.get("blind_rounds",0)>0: badges.append(["blind","Blinded: cannot act; damage breaks the effect"])
	if u.get("curse_rounds",0)>0: badges.append(["curse","Cursed: minimum damage"])
	if u.retaliated: badges.append(["retaliation","Retaliation used"])
	for j in range(badges.size()):
		var r=Rect2(450+(j%8)*66,498+(j/8)*60,54,54)
		detail_icon(badges[j][0],r,canvas)
		if r.has_point(get_global_mouse_position()): tooltip=badges[j][1]
	if can_detail_attack():
		canvas.draw_rect(Rect2(610,643,220,48),Color("d5bb83"))
		canvas.draw_rect(Rect2(610,643,220,48),GOLD,false,2)
		var ranged=can_shoot(current)
		var plan={} if ranged else approach(current,detail_id,{},true)
		var damage=damage_range(units[current],u,ranged,plan)
		detail_icon("ammo" if ranged else "attack",Rect2(623,647,40,40),canvas)
		center_text("%d–%d"%[damage.x,damage.y],Vector2(743,675),22,IVORY,null,canvas)
		if Rect2(610,643,220,48).has_point(get_global_mouse_position()): tooltip="Confirm ranged attack" if ranged else "Confirm melee attack"
	if not tooltip.is_empty():
		canvas.draw_rect(Rect2(436,560,568,77),Color("f5e8c9"))
		details_wrapped(tooltip,Vector2(450,582),538,canvas)

func pick_action_target(point: Vector2) -> int:
	var cell=mouse_cell(point)
	var occupied=occupant(cell) if valid(cell) else -1
	if occupied>=0: return occupied
	# A legal empty destination wins over an overhanging creature illustration.
	if not busy and not auto_on and current>=0 and units[current].side==player_side and reachable.has(cell): return -1
	return pick_creature(point)

func pick_creature(point: Vector2) -> int:
	var ids=[]
	for id in range(units.size()):
		if units[id].total>0: ids.append(id)
	ids.sort_custom(func(a,b): return units[a].visual.y>units[b].visual.y)
	for id in ids:
		if badge_body_rect(id).has_point(point): return id
	return occupant(mouse_cell(point))

func map_card(id: int) -> Rect2:
	return Rect2(405+id*160,786,150,64)

func select_map(id: int):
	if not choosing_faction or id<0 or id>=4: return
	map_id=id
	background=map_textures[id]
	obstacles.assign(Battlefields.OBSTACLES[id])
	soundtrack.set_battlefield(id)
	queue_redraw()

var action_cursor_key=""
var software_action_cursor=OS.get_name()=="macOS"
var cursor_inside=true
var action_cursors={}

func update_action_cursor():
	var key=""
	if cursor_inside and get_window().has_focus() and not opening_battle and not choosing_faction and not ended and detail_id<0 and not settings_open:
		var point=get_global_mouse_position()
		if Rect2(8,108,1424,646).has_point(point):
			var id=pick_action_target(point)
			if id>=0: key="inspect"
			if not busy and not auto_on and current>=0 and units[current].side==player_side:
				if id==current: key="move"
				elif id>=0 and units[id].side!=player_side and (can_shoot(current) or attack_cell(current,id).x>=0): key=ranged_cursor(current,id) if can_shoot(current) else "damage"
				elif id<0 and reachable.has(mouse_cell(point)): key="move"
	if key==action_cursor_key: return
	action_cursor_key=key
	if key.is_empty():
		Input.set_custom_mouse_cursor(null)
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		return
	if not action_cursors.has(key):
		var source=combat_icons[key].get_image()
		source.resize(32,32,Image.INTERPOLATE_LANCZOS)
		var outlined=Image.create(38,38,false,Image.FORMAT_RGBA8)
		for y in range(32):
			for x in range(32):
				if source.get_pixel(x,y).a>.15:
					for dy in range(-2,3):
						for dx in range(-2,3): outlined.set_pixel(x+3+dx,y+3+dy,Color("342b36"))
		outlined.blend_rect(source,Rect2i(0,0,32,32),Vector2i(3,3))
		action_cursors[key]=ImageTexture.create_from_image(outlined)
	if software_action_cursor:
		Input.set_custom_mouse_cursor(null)
		Input.mouse_mode=Input.MOUSE_MODE_HIDDEN
	else:
		Input.set_custom_mouse_cursor(action_cursors[key],Input.CURSOR_ARROW,Vector2(19,19))

func _exit_tree():
	Input.set_custom_mouse_cursor(null)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func draw_interaction(canvas: Node2D):
	if ended or choosing_faction or opening_battle or detail_id>=0: return
	var id=pick_action_target(get_global_mouse_position())
	if id>=0:
		var color=Color("8ad9dc") if units[id].side==player_side else Color("f2ae82")
		for cell in footprint(id):
			var edge=hex_points(cell,2); edge.append(edge[0])
			canvas.draw_polyline(edge,color,3,true)
	for attacker in units:
		if attacker.total>0 and attacker.anim in ["attack","shoot"]:
			var action_icon="damage"
			if attacker.anim=="shoot": action_icon=ranged_cursor(units.find(attacker),attacker.get("attack_target",0))
			canvas.draw_texture_rect(combat_icons[action_icon],Rect2(attacker.visual-Vector2(14,150),Vector2(28,28)),false)

func apply_creature_effects(a: int,b: int,ranged: bool,damage: int):
	if not ranged and units[b].total>0:
		if units[a].sprite==7 and not units[b].undead and units[b].sprite not in [20,33] and rng.randf()<0.2:
			units[b].curse_rounds=3
			floating("CURSE",units[b].visual-Vector2(0,150),RED)
			ability_feedback("curse",a,b)
		if units[a].sprite==19 and units[b].living and units[b].sprite not in [20,27,33] and rng.randf()<0.2:
			units[b].blind_rounds=3
			floating("BLIND",units[b].visual-Vector2(0,150),RED)
			ability_feedback("blind",a,b)
	if ranged or units[a].sprite not in [20,30]: return
	ability_feedback("breath" if units[a].sprite==20 else "triple",a,b)
	var victims=[]
	if units[a].sprite==30:
		for candidate in range(units.size()):
			if candidate!=b and candidate!=a and units[candidate].total>0 and units[candidate].side!=units[a].side and touches(a,candidate,units[a].pos) and stack_distance(candidate,b)==1: victims.append(candidate)
	else:
		# Continue one axial hex beyond the contact hex, not a visual cone.
		var contact=Vector2i(-1,-1)
		var origin=Vector2i(-1,-1)
		var distance=INF
		for start in footprint(a):
			for hit in footprint(b):
				if hex_distance(start,hit)!=1: continue
				var score=cell_center(start).distance_squared_to(units[a].visual)+cell_center(hit).distance_squared_to(units[b].visual)
				if score<distance: distance=score; origin=start; contact=hit
		if contact.x>=0:
			var aq=Vector2i(origin.x-(origin.y-(origin.y&1))/2,origin.y)
			var bq=Vector2i(contact.x-(contact.y-(contact.y&1))/2,contact.y)
			var next=bq+(bq-aq)
			var cell=Vector2i(next.x+(next.y-(next.y&1))/2,next.y)
			var victim=occupant(cell)
			if victim>=0 and victim not in [a,b]: victims.append(victim)
	if units[a].sprite==30 and victims.size()>2: victims.resize(2)
	for victim in victims:
		effects.append({"kind":"ability","skill":"breath" if units[a].sprite==20 else "triple","from":units[b].visual-Vector2(0,48),"to":units[victim].visual-Vector2(0,48),"t":0.0,"life":0.85})
		var previous: int=units[victim].total
		units[victim].total=maxi(0,previous-damage)
		receive_hit(victim,(units[victim].visual-units[a].visual).normalized())
		hit_feedback(victim,previous,damage)
	if not victims.is_empty(): floating("BREATH" if units[a].sprite==20 else "TRIPLE",units[a].visual-Vector2(0,150),GOLD)
