import bpy, math, os
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT=os.path.join(ROOT,'assets/griffin_clay');os.makedirs(OUT,exist_ok=True)
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
uv('Pear shaped lion body',(-.25,0,1.0),(.95,.52,.65),honey)
uv('Round eagle head',(.62,0,1.72),(.59,.48,.58),cream,'head')
uv('Chubby cheek',(.83,-.34,1.56),(.34,.22,.30),cream,'head')
uv('Upper hooked beak',(1.18,0,1.66),(.39,.27,.22),gold,'head', (0,.22,0))
uv('Beak hooked tip',(1.46,0,1.55),(.13,.20,.19),gold,'head')
uv('Lower beak',(1.19,0,1.48),(.26,.22,.095),gold,'head')
for y in [-1,1]:
 uv('Eye socket'+str(y),(.88,y*.403,1.91),(.205,.09,.23),honey,'head')
 uv('Bright eye'+str(y),(.94,y*.465,1.93),(.117,.052,.155),dark,'head')
 uv('Eye shine'+str(y),(.98,y*.509,1.987),(.034,.018,.045),white,'head')
 for j in range(3):uv('Crest feather',(.28-j*.11,y*.12,2.13+j*.06),(.11,.14,.32),cream,'head',(0,-.5,0))
 # feather scallops around neck
 for j in range(5):uv('Neck feather',(.35+j*.10,y*(.34+.02*j),1.48-j*.105),(.14,.11,.24),cream,'head',(0,.45,0))
 for x in [-.78,.52]:
  bone=('hind' if x<0 else 'fore')+str(y)
  uv('Leg', (x,y*.35,.48),(.22,.20,.38),honey if x<0 else cream,bone)
  uv('Paw',(x+.1,y*.35,.19),(.32,.24,.19),honey if x<0 else gold,bone)
  for t in [-1,0,1]:uv('Toe',(x+.31,y*.35+t*.12,.16),(.15,.065,.085),gold if x>0 else cream,bone)
 uv('Blue shoulder bib',(.56,y*.414,1.17),(.27,.07,.30),blue)
 uv('Harness medallion',(.70,y*.484,1.20),(.12,.035,.13),brass)
# Tail curved as a succession of soft clay segments.
for j in range(13):
 t=j/12;uv('Curved lion tail',(-1.0-.65*math.sin(t*1.8),.12, .95+.75*t),(.105,.10,.13),honey,'tail')
uv('Tail tuft',(-1.64,.12,1.75),(.21,.18,.25),cream,'tail',(0,-.4,0))
# Layered wings with individually modelled rounded feathers.
for sign in [-1,1]:
 bone='wing'+str(sign)
 uv('Wing shoulder',(-.34,sign*.44,1.40),(.42,.24,.38),cream,bone)
 for j in range(9):
  t=j/8
  uv('Primary feather %s %s'%(sign,j),(-.55-.62*t,sign*(.63+.23*t),1.62+.78*t),(.13,.105,.48+.13*t),cream,bone,(0,-.18-.65*t,sign*.18))
 for j in range(6):
  t=j/5;uv('Wing covert',(-.33-.60*t,sign*.77,1.48+.52*t),(.16,.085,.26),gold if j==0 else cream,bone,(0,-.55,0))
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
# Separate named actions, sampled into actual rendered frames.
for state in ['idle','fly','attack','hit','land']:
 rig.animation_data_create();action=bpy.data.actions.new('Griffin_'+state);rig.animation_data.action=action
 count=12 if state=='fly' else 9
 for f in range(count):
  t=f/(count if state=='fly' else count-1)
  for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)
  if state=='fly':
   for sign in [-1,1]:rig.pose.bones['wing'+str(sign)].rotation_euler.x=sign*(.8+math.sin(t*math.tau)*1.3)
   for k in ['fore','hind']:
    for sign in [-1,1]:rig.pose.bones[k+str(sign)].rotation_euler.x=.55
   rig.pose.bones['body'].location.y=.06*math.sin(t*math.tau)
  elif state=='attack':
   l=math.sin(t*math.pi);rig.pose.bones['head'].rotation_euler.x=-.5*l;rig.pose.bones['body'].rotation_euler.x=-.20*l
   for sign in [-1,1]:rig.pose.bones['fore'+str(sign)].rotation_euler.x=-.9*l;rig.pose.bones['wing'+str(sign)].rotation_euler.x=sign*.8*l
  elif state=='hit':rig.pose.bones['body'].rotation_euler.x=.25*math.sin(t*math.pi);rig.pose.bones['head'].rotation_euler.x=.3*math.sin(t*math.pi)
  elif state=='land':
   for sign in [-1,1]:rig.pose.bones['wing'+str(sign)].rotation_euler.x=sign*1.5*(1-t)
   rig.pose.bones['body'].location.y=-.12*math.sin(t*math.pi)
  else:rig.pose.bones['head'].rotation_euler.x=.025*math.sin(t*math.tau)
  for b in rig.pose.bones:b.keyframe_insert('rotation_euler',frame=f+1);b.keyframe_insert('location',frame=f+1)
  scene.frame_set(f+1);folder=os.path.join(OUT,state);os.makedirs(folder,exist_ok=True);scene.render.filepath=os.path.join(folder,'%02d.png'%f);bpy.ops.render.render(write_still=True)
rig.animation_data.action=bpy.data.actions.get('Griffin_idle');scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art/griffin/griffin_clay.blend'))
print('GRIFFIN RENDER COMPLETE')
