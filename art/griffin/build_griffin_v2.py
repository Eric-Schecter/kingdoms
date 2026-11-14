import bpy, math, os
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT=os.path.join(ROOT,'assets/griffin_clay_v2');os.makedirs(OUT,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,rough=.65,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
honey=mat('Warm honey clay',(.57,.28,.075));cream=mat('Ivory feather clay',(.94,.82,.59));gold=mat('Golden beak',(.95,.56,.09));dark=mat('Warm black eyes',(.028,.018,.012),.25);white=mat('Eye glints',(1,.97,.84),.2);blue=mat('Royal blue harness',(.045,.19,.38));brass=mat('Antique gold trim',(.67,.43,.12),.35,.35)
parts={}
def uv(name,loc,scale,material,bone='body',rot=None):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=loc);o=bpy.context.object;o.name=name;o.scale=scale
 if rot:o.rotation_euler=rot
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(material)
 for p in o.data.polygons:p.use_smooth=True
 parts[o.name]=bone
 return o
# Sculpted tapered feather mesh, with a raised quill and rounded blade edges.
def strand(name,points,radius,material,bone='body'):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=radius;c.bevel_resolution=3
 sp=c.splines.new('BEZIER');sp.bezier_points.add(len(points)-1)
 for p,co in zip(sp.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(material)
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');parts[o.name]=bone;o.select_set(False)
 return o

def feather(name,start,end,width,material,bone='body',normal=(0,-1,0)):
 start=Vector(start);end=Vector(end);axis=end-start;n=Vector(normal).normalized();side=axis.normalized().cross(n).normalized()
 verts=[];faces=[]
 for j in range(13):
  t=j/12;w=width*(math.sin(math.pi*t)**.55)*(.92-.25*t)+.006
  center=start+axis*t+n*(.065*math.sin(math.pi*t))
  for k in range(9):
   a=k*math.tau/8;v=center+side*w*math.cos(a)+n*(width*.24*math.sin(a));verts.append(v)
 for j in range(12):
  for k in range(8):a=j*9+k;faces.append((a,a+1,a+10,a+9))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(material)
 for p in mesh.polygons:p.use_smooth=True
 sub=o.modifiers.new('Soft sculpt surface','SUBSURF');sub.levels=1
 parts[o.name]=bone
 strand(name+' quill',[start+n*.025,start+axis*.45+n*.09,start+axis*.88+n*.04],.008,cream,bone)
 return o

uv('Full pear shaped torso',(-.27,0,.96),(.84,.64,.79),honey)
uv('Seated haunch',(-.80,.0,.58),(.55,.61,.49),honey)
uv('Broad ivory eagle head',(.52,0,1.89),(.62,.60,.61),cream,'head')
uv('Breast mane foundation',(.43,0,1.23),(.51,.59,.63),cream)
# Short contiguous hooked bill, rather than a long cylindrical muzzle.
uv('Beak base',(.99,0,1.81),(.30,.33,.21),gold,'head',(0,.16,0))
feather('Hooked upper bill',(1.10,0,1.88),(1.36,0,1.64),.18,gold,'head',(0,0,1))
uv('Smile dark interior',(1.04,0,1.63),(.235,.25,.075),dark,'head')
uv('Lower bill',(1.07,0,1.58),(.25,.26,.065),gold,'head')
for sign in [-1,1]:
 y=sign
 uv('Large eye ivory rim',(.79,y*.506,2.02),(.235,.095,.255),white,'head')
 uv('Amber iris',(.845,y*.58,2.025),(.147,.042,.185),gold,'head')
 uv('Expressive pupil',(.865,y*.611,2.035),(.092,.025,.13),dark,'head')
 uv('Eye highlight',(.90,y*.634,2.095),(.028,.014,.036),white,'head')
 feather('Soft eyebrow',(.60,y*.56,2.24),(.99,y*.51,2.20),.085,cream,'head',(0,sign,0))
 for j in range(4):
  feather('Swept cheek feather',(.55-j*.085,y*.53,1.91-j*.09),(.17-j*.11,y*.58,1.78-j*.10),.12,cream,'head',(0,sign,0))
 for j in range(4):
  feather('Head crest',(.32-j*.12,y*.14,2.23),(.10-j*.18,y*.16,2.52-j*.04),.11,cream,'head',(0,sign,0))
 # Broad layered wing fan, each feather has a separate sculpted blade.
 bone='wing'+str(sign)
 uv('Wing root',(-.40,y*.56,1.40),(.38,.16,.38),cream,bone)
 for j in range(10):
  t=j/9
  feather('Flight feather',(-.39-.23*t,y*.68,1.38+.20*t),(-.63-.95*t,y*(.75+.08*t),2.75-.70*t*t),.125,cream,bone,(0,sign,0))
 for row in range(2):
  for j in range(7):
   t=j/6
   feather('Layered wing covert',(-.28-.68*t,y*(.80+row*.035),1.42+.20*t+row*.19),(-.52-.77*t,y*(.83+row*.035),1.76+.24*t+row*.20),.12,gold if row==0 else cream,bone,(0,sign,0))
 for x,k in [(-.76,'hind'),(.56,'fore')]:
  bone=k+str(sign)
  uv('Stout limb',(x,y*.45,.43),(.23,.23,.36),honey if k=='hind' else cream,bone)
  uv('Oversize lion paw',(x+.10,y*.45,.17),(.36,.30,.20),honey if k=='hind' else gold,bone)
  for toe in range(3):
   yy=y*.45+(toe-1)*.17
   uv('Rounded toe',(x+.32,yy,.17),(.17,.095,.125),gold if k=='fore' else honey,bone)
   feather('Small claw',(x+.39,yy,.20),(x+.53,yy,.10),.045,dark,bone,(0,0,1))
# Scalloped shoulder feathers conceal the root joint.
for sign in [-1,1]:
 for row in range(3):
  for j in range(5):
   x=-.12-j*.12;z=1.58-row*.12+.04*math.sin(j)
   feather('Shoulder plumage',(x,sign*.77,z),(x-.14,sign*.80,z+.20),.095,cream,'wing'+str(sign),(0,sign,0))
# Overlapping chest plumage.
for row in range(4):
 for j in range(7):
  angle=-1.22+j*.40
  x=.46+.39*math.cos(angle);y=.55*math.sin(angle);z=1.65-row*.17+.035*math.sin(j*2+row)
  y+=.035*(row%2)
  feather('Breast feather',(x,y,z),(x+.02,y*1.05,z-.30),.105,cream,'body',(math.cos(angle),math.sin(angle),0))
# A smooth curled lion tail and a feather-like sculpted tuft.
strand('Curled tail',[(-1,0,.68),(-1.52,.1,.86),(-1.73,.15,1.36),(-1.49,.16,1.59),(-1.30,.14,1.38)],.09,honey,'tail')
for j in range(5):feather('Tail tuft',(-1.30,.14,1.37),(-1.05+j*.065,.10+(j%2)*.10,1.56-j*.09),.10,honey,'tail')
# Royal breast badge and harness.
uv('Blue enamel badge',(.94,-.31,1.04),(.085,.20,.23),blue)
strand('Gold badge rim',[(1.00,-.48,1.18),(1.04,-.31,1.25),(1.00,-.14,1.18),(1.01,-.19,.93),(1.02,-.31,.83),(1.01,-.43,.93),(1.00,-.48,1.18)],.022,brass)
uv('Badge gold crest',(1.03,-.31,1.06),(.025,.08,.10),brass)
# Real editable armature, rigid per-part vertex weights.
bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0));rig=bpy.context.object;rig.name='Griffin_Rig';eb=rig.data.edit_bones;eb.remove(eb[0])
bones={'body':((0,0,.7),(0,0,1.3),None),'head':((.35,0,1.4),(.6,0,2.0),'body'),'tail':((-1,0,1),(-1.5,0,1.6),'body')}
for sign in [-1,1]:
 bones['wing'+str(sign)]=((-.3,sign*.43,1.4),(-.3,sign*.43+1,1.4),'body')
 for x,k in [(-.78,'hind'),(.52,'fore')]:bones[k+str(sign)]=((x,sign*.35,.75),(x,sign*.35,.20),'body')
for n,(h,t,p) in bones.items():
 b=eb.new(n);b.head=h;b.tail=t
 if p:b.parent=eb[p]
bpy.ops.object.mode_set(mode='OBJECT')
for name,bone in parts.items():
 o=bpy.data.objects[name];g=o.vertex_groups.new(name=bone);g.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Skeleton','ARMATURE');mod.object=rig;o.parent=rig
for b in rig.pose.bones:b.rotation_mode='XYZ'
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=320;scene.render.resolution_y=320;scene.render.resolution_percentage=100;scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.world.color=(.3,.3,.3)
def point(o,target):o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(4,-8,3.4));camera=bpy.context.object;point(camera,(0,0,1.25));camera.data.type='ORTHO';camera.data.ortho_scale=4.4;scene.camera=camera
for loc,power,size in [((1,-4,6),650,4),((-4,-1,3),350,3),((0,4,5),750,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;point(o,(0,0,1))

# Fine clay microtexture; subtle enough to survive a small sprite render.
for m in [honey,cream,gold]:
 tree=m.node_tree;noise=tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=90;noise.inputs['Detail'].default_value=2
 bump=tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.16;bump.inputs['Distance'].default_value=.025
 tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);tree.links.new(bump.outputs['Normal'],tree.nodes.get('Principled BSDF').inputs['Normal'])
# Static sculpt review before animation work.
scene.cycles.samples=64
scene.render.resolution_x=1024;scene.render.resolution_y=1024
camera.location=(4.4,-8,3.1);point(camera,(-.10,0,1.23));camera.data.ortho_scale=4.25
scene.render.film_transparent=False
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.30,.25,.19,1)
# Matte studio floor and warm ambient backdrop.
floor=mat('Warm ivory studio',(.67,.59,.47),.9)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.045));bpy.context.object.data.materials.append(floor)
scene.render.filepath=os.path.join(ROOT,'output/griffin-v2-sculpt.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art/griffin/griffin_clay_v2.blend'))
print('SCULPT V2 COMPLETE')
