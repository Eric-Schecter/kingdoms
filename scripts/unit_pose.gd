extends Node2D
## Independent painted animation frames; no mesh distortion or vertex shader.
var skin: Texture2D
var clips={}
var kind=0
var current_frame: Texture2D
var idle_frame: Texture2D
var storybook=false
var story_frames: Array[Texture2D]=[]
var story_index=0
var story_origins: Array[Vector2]=[]
var story_scale=1.0
var flight_frames: Array[Texture2D]=[]
var flight_origins: Array[Vector2]=[]
var flight_scale=1.0
var airborne=false
var flight_index=0
const FLAP_SEQUENCE=[0,1,2,2,3,0]
# Eye landmarks in the 418px source cells: wings never drive body registration.
const FLIGHT_EYES={
 3:[Vector2(314,139),Vector2(318,139),Vector2(317,128),Vector2(317,128)],
 17:[Vector2(311,140),Vector2(312,143),Vector2(312,135),Vector2(307,128)],
 20:[Vector2(317,146),Vector2(319,143),Vector2(317,130),Vector2(315,130)],
 22:[Vector2(308,155),Vector2(309,155),Vector2(308,142),Vector2(309,142)]}
func setup_flight():
 if kind in [10,13]:
  var sheet=load("res://assets/storybook/airborne-angel-bone-dragon.png")
  var cell=sheet.get_size()/Vector2(4,2)
  flight_scale=story_scale*418.0/cell.x
  var eye=Vector2(0.72,0.35) if kind==10 else Vector2(0.78,0.32)
  var target=story_origins[0]+(Vector2(279,121) if kind==10 else Vector2(326,164))*story_scale
  for i in range(4):
   var frame=AtlasTexture.new()
   frame.atlas=sheet
   frame.region=Rect2(Vector2(i,0 if kind==10 else 1)*cell,cell)
   frame.filter_clip=true
   flight_frames.append(frame)
   flight_origins.append(target-eye*cell*flight_scale)
 elif FLIGHT_EYES.has(kind):
  flight_scale=0.48 if kind==3 else story_scale
  var target=Vector2(18,-110) if kind==3 else story_origins[0]+FLIGHT_EYES[kind][0]*story_scale
  for i in range(4):
   flight_frames.append(story_frames[i+1])
   flight_origins.append(target-FLIGHT_EYES[kind][i]*flight_scale)

static var registration_cache={}
func solid_bounds(img: Image) -> Rect2i:
 var lo=img.get_size()
 var hi=Vector2i.ZERO
 for y in range(0,img.get_height(),2):
  for x in range(0,img.get_width(),2):
   if img.get_pixel(x,y).a>0.5:
    lo=lo.min(Vector2i(x,y))
    hi=hi.max(Vector2i(x+2,y+2))
 return Rect2i(lo,hi-lo)
const STORY_NAMES=["pikeman","marksman","crusader","griffin","skeleton","zombie","lich","dread-knight","monk","knight","angel","ghost","vampire","bone-dragon","centaur","dwarf","wood-elf","pegasus","dendroid","unicorn","green-dragon","gremlin","gargoyle","iron-golem","mage","genie","naga","titan","imp","gog","hell-hound","demon","pit-fiend","efreet","devil"]
const STORY_HEIGHTS=[128.0,110.0,120.0,124.0,110.0,110.0,132.0,146.0,118.0,146.0,148.0,122.0,124.0,156.0,144.0,100.0,115.0,146.0,150.0,146.0,156.0,96.0,110.0,125.0,125.0,140.0,150.0,158.0,95.0,110.0,125.0,140.0,148.0,145.0,156.0]
# Local eye positions measured on the 1280px authoring sheet.
const STORY_EYES=[Vector2(308,150),Vector2(280,150),Vector2(282,150),Vector2(310,103),Vector2(283,93),Vector2(277,93)]
const STORY_FLIGHT=[1,2,3,4,4,5,5,2]
var clay=false
var painted=false
var painted_pose="master"
# Eye registration, not alpha bounds: changing wings must not resize the body.
const PAINTED_REGISTRATION={
 "master": Vector3(711,290,0.14),
 "01-up": Vector3(700,470,0.17),
 "02-out": Vector3(685,440,0.18),
 "03-down": Vector3(700,375,0.18),
 "04-recover": Vector3(710,395,0.17),
 "05-rise": Vector3(685,440,0.18),
}
var painted_frames={}
# Fast power stroke, slower folded recovery. These are separate PNG drawings.
const WING_SEQUENCE=["01-up","05-rise","02-out","03-down","03-down","04-recover","04-recover","05-rise"]
func setup(texture: Texture2D, creature: int):
 skin=texture
 kind=creature
 var story_path="res://assets/storybook/%s-sheet.png" % STORY_NAMES[kind]
 storybook=ResourceLoader.exists(story_path)
 if storybook:
  var sheet: Texture2D=load(story_path)
  for i in range(9):
   var atlas=AtlasTexture.new()
   atlas.atlas=sheet
   var cell=sheet.get_size()/3.0
   atlas.region=Rect2(Vector2(i%3,i/3)*cell,cell)
   # These attack drawings extend into their otherwise empty right gutter.
   if kind in [2,6] and i==6: atlas.region.size.x+=cell.x*0.055
   if kind in [2,6] and i==7:
    atlas.region.position.x+=cell.x*0.055
    atlas.region.size.x-=cell.x*0.055
   atlas.filter_clip=true
   story_frames.append(atlas)
  if kind!=3:
   if registration_cache.has(kind):
    story_scale=registration_cache[kind].scale
    story_origins.assign(registration_cache[kind].origins)
   else:
    var bounds=solid_bounds(story_frames[0].get_image())
    story_scale=STORY_HEIGHTS[kind]/maxf(1.0,bounds.size.y)
    for frame in story_frames:
     var used=solid_bounds(frame.get_image())
     story_origins.append(Vector2(-(used.position.x+used.size.x*0.5),-used.end.y)*story_scale+Vector2(0,8))
    registration_cache[kind]={"scale":story_scale,"origins":story_origins.duplicate()}
  setup_flight()
  idle_frame=story_frames[0]
  current_frame=idle_frame
  queue_redraw()
  return
 painted=kind==3 and ResourceLoader.exists("res://assets/griffin_2d/master.png")
 if painted:
  for pose in PAINTED_REGISTRATION:
   var path="res://assets/griffin_2d/%s.png" % pose
   if ResourceLoader.exists(path): painted_frames[pose]=load(path)
  idle_frame=painted_frames.master
  current_frame=idle_frame
  queue_redraw()
  return
 clay=kind==3 and ResourceLoader.exists("res://assets/griffin_clay/idle/00.png")
 for state in ["idle","walk","fly","attack","shoot","hit","death","land"]:
  var frames: Array[Texture2D]=[]
  for i in range(12 if clay else 9):
   var path="res://assets/animations/%d/%s/%02d.png" % [kind,state,i]
   if clay: path="res://assets/griffin_clay/%s/%02d.png" % [state,i]
   if ResourceLoader.exists(path): frames.append(load(path))
  if not frames.is_empty():
   if state=="fly" and not clay:
    for j in range(7,0,-1): frames.append(frames[j])
   clips[state]=frames
 idle_frame=skin
 for state in ["idle","walk","fly","attack","shoot","hit"]:
  if clips.has(state):
   idle_frame=clips[state][0]
   break
 current_frame=idle_frame
 queue_redraw()
func update_pose(state: String, elapsed: float, duration: float, hit: float):
 if storybook:
  airborne=state in ["fly","takeoff"] or (state=="land" and elapsed<duration*0.7)
  if airborne and not flight_frames.is_empty():
   flight_index=3 if state=="land" else FLAP_SEQUENCE[int(elapsed*8.0)%FLAP_SEQUENCE.size()]
   current_frame=flight_frames[flight_index]
   queue_redraw()
   return
  story_index=0
  var t=clampf(elapsed/maxf(duration,0.001),0.0,1.0)
  if kind!=3:
   if state=="walk": story_index=1+int(elapsed*10.0)%4
   elif state=="fly":
    # Levitation/teleport creatures must never cycle their walking legs.
    story_index=5 if kind==12 else (0 if kind==34 else 1+int(elapsed*6.0)%4)
   elif state in ["attack","shoot"]:
    story_index=5 if t<0.36 else (6 if t<0.70 else (7 if t<0.92 else 0))
   elif state=="hit": story_index=8 if t<0.8 else 0
   elif state=="death": story_index=8
  elif state=="fly": story_index=STORY_FLIGHT[int(elapsed*12.0)%STORY_FLIGHT.size()]
  elif state=="land": story_index=5 if t<0.5 else 0
  elif state=="attack":
   story_index=6 if t<0.36 else (7 if t<0.76 else 0)
  elif state=="hit": story_index=8 if t<0.8 else 0
  elif state=="death": story_index=8
  current_frame=story_frames[story_index]
  queue_redraw()
  return
 if painted:
  painted_pose="master"
  if state=="fly":
   painted_pose=WING_SEQUENCE[int(elapsed*12.0)%WING_SEQUENCE.size()]
  elif state=="land":
   painted_pose="04-recover" if elapsed < duration*0.55 else "master"
  current_frame=painted_frames.get(painted_pose,idle_frame)
  queue_redraw()
  return
 if clips.has(state):
  var frames: Array=clips[state]
  var index=0
  if clay and state in ["idle","fly"]: index=int(elapsed*12.0)%frames.size()
  elif state in ["walk","fly"]: index=1+int(elapsed*10.0)%maxi(1,frames.size()-1)
  else:
   var t=clampf(elapsed/maxf(duration,0.001),0,1)
   if state in ["attack","shoot"] and not clay:
    var sequence=[0,1,2,3,4,5,6,7,8,7,5,2,0]
    index=sequence[mini(sequence.size()-1,int(t*sequence.size()))]
   else: index=mini(frames.size()-1,int(t*(frames.size()-1)))
  current_frame=frames[index]
 else: current_frame=idle_frame
 queue_redraw()
func _draw():
 if not current_frame: return
 if storybook and airborne and not flight_frames.is_empty():
  draw_texture_rect(current_frame,Rect2(flight_origins[flight_index],current_frame.get_size()*flight_scale),false)
 elif storybook and kind!=3:
  draw_texture_rect(current_frame,Rect2(story_origins[story_index],current_frame.get_size()*story_scale),false)
 elif storybook:
  var origin=Vector2(-130,-182)
  if story_index<6:
   origin=Vector2(18,-110)-STORY_EYES[story_index]*0.48
  # Attack/hit keep the ground baseline; their head displacement is intentional.
  else: origin=Vector2(-130,-164)
  draw_texture_rect(current_frame,Rect2(origin,current_frame.get_size()*0.48),false)
 elif painted:
  var registration: Vector3=PAINTED_REGISTRATION[painted_pose]
  var pixel_scale=registration.z
  var origin=Vector2(14,-110)-Vector2(registration.x,registration.y)*pixel_scale
  draw_texture_rect(current_frame,Rect2(origin,current_frame.get_size()*pixel_scale),false)
 elif clay:
  draw_texture_rect(current_frame,Rect2(-100,-167,200,200),false)
 elif current_frame!=skin:
  draw_texture_rect(current_frame,Rect2(-80,-142,160,160),false)
 else:
  var h=124.0 if kind in [3,7] else (116.0 if kind==0 else 106.0)
  var w=h*skin.get_width()/skin.get_height()
  draw_texture_rect(skin,Rect2(-w/2,-h,w,h),false)
