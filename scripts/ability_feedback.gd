extends RefCounted
# Brief illustrated accents, drawn independently of creature poses.
const COLORS={"blind":Color("ffe7a0"),"curse":Color("b28ad0"),"death_blow":Color("d45665"),"disease":Color("96b26b"),"root":Color("769451"),"fire":Color("f5ab55"),"drain":Color("be7196"),"breath":Color("ffc779"),"triple":Color("f4dcae")}
static func draw(c: Node2D,e: Dictionary):
 var t: float=clampf(e.t/e.life,0,1)
 var a: float=sin(PI*pow(t,0.65))
 var p: Vector2=e.to
 var color: Color=COLORS.get(e.skill,Color.WHITE)
 color.a=a
 match e.skill:
  "root":
   for j in range(5):
    var vine=PackedVector2Array()
    for k in range(16):
     var h=float(k)/15*75*minf(1,t*4)
     vine.append(p+Vector2((j-2)*13+sin(h/15+j)*10,45-h))
    c.draw_polyline(vine,Color("514c32")*Color(1,1,1,a),6,true)
    c.draw_polyline(vine,color,3,true)
    var tip=vine[-1]
    c.draw_colored_polygon(PackedVector2Array([tip,tip+Vector2(-12,-9),tip+Vector2(-4,7)]),color)
  "blind":
   for j in range(8):
    var d=Vector2.from_angle(j*TAU/8+t*.6)
    var q=p+Vector2(0,-38)+d*(12+28*t)
    c.draw_line(q-d*5,q+d*8,color,3,true)
   c.draw_arc(p+Vector2(0,-38),20,-PI,0,24,color,4,true)
   c.draw_line(p+Vector2(-24,-50),p+Vector2(24,-26),color,4,true)
  "curse","death_blow":
   var center=p+Vector2(0,-45-16*t)
   c.draw_circle(center,17,color)
   for x in [-7,7]: c.draw_circle(center+Vector2(x,-2),5,Color("352636")*Color(1,1,1,a))
   for x in [-8,0,8]: c.draw_line(center+Vector2(x,10),center+Vector2(x,23),color,5,true)
   for j in range(6):
    var d=Vector2.from_angle(j*TAU/6)
    c.draw_line(center+d*(28+12*t),center+d*(38+20*t),color,3,true)
   if e.skill=="death_blow":
    c.draw_line(p+Vector2(-40,-65),p+Vector2(35,25),color,7*(1-t),true)
  "disease":
   for j in range(12):
    var q=p+Vector2(sin(j*4.1)*34,25-fmod(t*85+j*13,85))
    c.draw_circle(q,4+sin(j+t*5)*2,color)
    c.draw_arc(q,8,0,PI,12,Color(color,a*.35),2,true)
  "drain":
   for j in range(10):
    var u=clampf(t*1.5-j*.045,0,1)
    var q=Vector2(e.from).lerp(p,u)+Vector2(0,-sin(u*PI)*38)
    c.draw_circle(q,3+3*sin(u*PI),Color(color,a*(1-j*.055)))
   c.draw_line(p-Vector2(9,0),p+Vector2(9,0),color,4,true)
   c.draw_line(p-Vector2(0,9),p+Vector2(0,9),color,4,true)
  "fire","breath":
   for j in range(22):
    var u=fmod(t*1.8+j*.043,1.0)
    var q: Vector2
    if e.skill=="breath": q=Vector2(e.from).lerp(p,u)+Vector2(0,sin(j*7.1)*u*20)
    else: q=p+Vector2(sin(j*7.1)*34,38-u*100)
    var r=(5+u*9)*(1-t*.5)
    c.draw_colored_polygon(PackedVector2Array([q+Vector2(-r,4),q+Vector2(-r*.4,-r),q+Vector2(3,-r*2),q+Vector2(r,5)]),Color(color,a*(1-u*.5)))
    c.draw_circle(q,r*.35,Color("fff0b0")*Color(1,1,1,a))
  "triple":
   for j in range(3):
    var q=p+Vector2((j-1)*15,-12)
    c.draw_line(q+Vector2(-12,-22),q+Vector2(9,24)*minf(t*4,1),color,4,true)
static func statuses(c: Node2D,u: Dictionary,icons: Dictionary):
 var keys=[]
 if u.get("blind_rounds",0)>0: keys.append("blind")
 if u.get("curse_rounds",0)>0: keys.append("curse")
 if u.get("diseased",false): keys.append("disease")
 if u.get("rooted",false): keys.append("root")
 for j in range(keys.size()):
  var pos: Vector2=u.visual+Vector2(-keys.size()*11+j*22,-112)
  c.draw_style_box(status_box(),Rect2(pos,Vector2(21,21)))
  c.draw_texture_rect(icons[keys[j]],Rect2(pos+Vector2(2,2),Vector2(17,17)),false,COLORS[keys[j]])
static func status_box() -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=Color("40333e")
 s.set_corner_radius_all(4)
 return s
