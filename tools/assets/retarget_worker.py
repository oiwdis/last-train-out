"""Rest-pose alignment, CC0 motion retargeting, original carry/climb poses, matching FP arms."""
import os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
SOURCES = Path(os.environ.get("LTO_SOURCE_DIR", "/tmp/last-train-out-assets/sources"))
MPFB = Path(os.environ.get("LTO_MPFB_SOURCE", "/tmp/last-train-out-assets/mpfb2"))
HUMAN_DATA = Path(os.environ.get("LTO_MAKEHUMAN_DATA", "/tmp/last-train-out-assets/makehuman"))
BUILD = Path(os.environ.get("LTO_BUILD_DIR", "/tmp/last-train-out-assets/build"))
BUILD.mkdir(parents=True, exist_ok=True)
import bpy,pathlib,math,json
from mathutils import Vector,Matrix,Quaternion
bpy.ops.wm.open_mainfile(filepath=str(BUILD/'worker-source.blend'))
target=next(o for o in bpy.data.objects if o.type=='ARMATURE');meshes=[o for o in bpy.data.objects if o.type=='MESH']
bpy.ops.import_scene.gltf(filepath=str(next((SOURCES/'animations').rglob('UAL1_Standard.glb'))))
source=next(o for o in bpy.data.objects if o.type=='ARMATURE' and o!=target)
source.animation_data.use_nla=False;source.animation_data.action=None
for p in source.pose.bones:p.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
base={'Hips':'pelvis','Spine':'spine_01','Spine1':'spine_02','Spine2':'spine_03','Neck':'neck_01','Head':'Head'}
for side,suffix in [('Left','l'),('Right','r')]:
 for a,b in [('Shoulder','clavicle'),('Arm','upperarm'),('ForeArm','lowerarm'),('Hand','hand'),('UpLeg','thigh'),('Leg','calf'),('Foot','foot'),('ToeBase','ball')]:base[side+a]=b+'_'+suffix
 for f in ['Thumb','Index','Middle','Ring','Pinky']:
  for i in range(1,4):base[side+'Hand'+f+str(i)]=f.lower()+'_0'+str(i)+'_'+suffix
mapping={'mixamorig:'+a:b for a,b in base.items()}
# Put the authored target in the source rest posture with shortest-arc swings.
# Retain each target bone's anatomical roll, avoiding wrist/forearm twists.
for bone in target.data.bones:
 if bone.name not in mapping or not any(part in bone.name for part in ['Shoulder', 'Arm', 'Hand']):continue
 p=target.pose.bones[bone.name];s=source.data.bones[mapping[bone.name]]
 current=(p.tail-p.head).normalized();desired=(s.tail_local-s.head_local).normalized();q=current.rotation_difference(desired)
 matrix=p.matrix.copy();matrix= q.to_matrix().to_4x4() @ matrix;matrix.translation=p.head;p.matrix=matrix;bpy.context.view_layer.update()
for obj in meshes:
 bpy.context.view_layer.objects.active=obj
 for mod in list(obj.modifiers):
  if mod.type=='ARMATURE':bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.context.view_layer.objects.active=target;target.select_set(True);bpy.ops.object.mode_set(mode='POSE');bpy.ops.pose.armature_apply(selected=False);bpy.ops.object.mode_set(mode='OBJECT');target.select_set(False)
for obj in meshes:
 mod=obj.modifiers.new('Skin weights','ARMATURE');mod.object=target
# FP clips relocate the two arm roots below the eye. Connected bones ignore translation.
bpy.context.view_layer.objects.active=target;target.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name in ['mixamorig:LeftArm','mixamorig:RightArm']:
 target.data.edit_bones[name].use_connect=False
bpy.ops.object.mode_set(mode='OBJECT');target.select_set(False)
rest={b.name:b.matrix_local.copy() for b in target.data.bones}
srest={b.name:b.matrix_local.copy() for b in source.data.bones}
target.animation_data_create();target.animation_data.use_nla=False
bpy.context.scene.render.fps=24
clips={'idle':'Idle_Loop','walk':'Walk_Loop','jog':'Jog_Fwd_Loop','sprint':'Sprint_Loop','jump':'Jump_Start','fall':'Jump_Loop','land':'Jump_Land','pickup':'PickUp_Table','operate':'Interact','push':'Push_Loop'}
produced={}
for name,src in clips.items():
 original=bpy.data.actions[src+'_Armature'];source.animation_data.action=original;action=bpy.data.actions.new(name);target.animation_data.action=action
 count=math.ceil(original.frame_range[1]);prev={}
 for frame in range(count+1):
  bpy.context.scene.frame_set(frame);posed={}
  for bone in target.data.bones:
   n=bone.name;parent=bone.parent;local=rest[parent.name].inverted()@rest[n] if parent else rest[n];parent_pose=posed[parent.name] if parent else Matrix.Identity(4);desired=parent_pose@local
   if n in mapping:
    sn=mapping[n];delta=source.pose.bones[sn].matrix.to_quaternion()@srest[sn].to_quaternion().inverted();rot=delta@rest[n].to_quaternion();location=desired.translation.copy();desired=rot.to_matrix().to_4x4();desired.translation=location
    if n=='mixamorig:Hips':
     hip_delta=source.pose.bones[sn].matrix.translation-srest[sn].translation
     # In-place controller owns forward travel. Keep lateral sway and vertical
     # bounce, discard forward translation even when the source action moves.
     desired.translation=rest[n].translation+Vector((hip_delta.x,0,hip_delta.z))*.97
   basis=local.inverted()@parent_pose.inverted()@desired;p=target.pose.bones[n];p.matrix_basis=basis;p.rotation_mode='QUATERNION'
   if n in prev and p.rotation_quaternion.dot(prev[n])<0:p.rotation_quaternion.negate()
   prev[n]=p.rotation_quaternion.copy();p.keyframe_insert('rotation_quaternion',frame=frame,group=n);p.keyframe_insert('location',frame=frame,group=n);posed[n]=desired
 for curve in action.fcurves:
  for key in curve.keyframe_points:key.interpolation='LINEAR'
 action.use_fake_user=True;produced[name]=action;print('RETARGET',name,count,flush=True)
# Original task-specific poses use the same weighted anatomy and solved two-bone limbs.
def aim(bone_name, destination):
 p=target.pose.bones['mixamorig:'+bone_name];q=(p.tail-p.head).normalized().rotation_difference((Vector(destination)-p.head).normalized());m=q.to_matrix().to_4x4()@p.matrix;m.translation=p.head;p.matrix=m;bpy.context.view_layer.update()
def limb(side,upper,lower,end,destination,pole):
 a=target.pose.bones['mixamorig:'+side+upper];b=target.pose.bones['mixamorig:'+side+lower];c=target.pose.bones['mixamorig:'+side+end];start=a.head.copy();dest=Vector(destination);direction=dest-start;d=min(direction.length,a.length+b.length-.003);u=direction.normalized();v=(Vector(pole)-start);v=(v-u*v.dot(u)).normalized();x=(a.length*a.length-b.length*b.length+d*d)/(2*d);height=math.sqrt(max(0,a.length*a.length-x*x));elbow=start+u*x+v*height;aim(side+upper,elbow);aim(side+lower,start+u*d)
def reset_from(clip,frame):
 target.animation_data.action=produced[clip];bpy.context.scene.frame_set(int(frame), subframe=frame-int(frame));bpy.context.view_layer.update();return {b.name:b.matrix_basis.copy() for b in target.pose.bones}
def restore(pose):
 target.animation_data.action=None
 for name,m in pose.items():target.pose.bones[name].matrix_basis=m
 bpy.context.view_layer.update()
# A neutral worker stance replaces the source library's combat-ready idle.
# Keep relaxed finger articulation from the source, but stand upright with arms at the sides.
source_idle = produced['idle']
target.animation_data.action = source_idle
bpy.context.scene.frame_set(12)
finger_pose = {p.name: p.rotation_quaternion.copy() for p in target.pose.bones if 'Hand' in p.name and p.name[-1:].isdigit()}
neutral = bpy.data.actions.new('worker_breathing')
for frame in range(73):
 target.animation_data.action = None
 for p in target.pose.bones: p.matrix_basis = Matrix.Identity(4)
 bpy.context.view_layer.update()
 for side,sign in [('Left',1),('Right',-1)]:
  limb(side,'Arm','ForeArm','Hand',(sign*.22,-.035,.89),(sign*.38,.12,1.15))
  aim(side+'Hand',(sign*.22,-.04,.78))
 for name,rotation in finger_pose.items():
  target.pose.bones[name].rotation_quaternion=Quaternion().slerp(rotation,.48)
 phase=frame/72*math.tau
 target.pose.bones['mixamorig:Spine2'].rotation_quaternion=Quaternion((1,0,0),math.sin(phase)*.007)
 target.pose.bones['mixamorig:Neck'].rotation_quaternion=Quaternion((0,1,0),math.sin(phase)*.004)
 target.animation_data.action=neutral
 for p in target.pose.bones:
  p.rotation_mode='QUATERNION';p.keyframe_insert('rotation_quaternion',frame=frame,group=p.name);p.keyframe_insert('location',frame=frame,group=p.name)
source_idle.name='source_combat_idle'
neutral.name='idle';neutral.use_fake_user=True;produced['idle']=neutral
for name,length in [('carry',48),('carry_walk',32),('climb',32),('hang',48),('vault',24),('drop',20)]:
 action=bpy.data.actions.new(name)
 for frame in range(length+1):
  clip='walk' if name=='carry_walk' else 'jump' if name=='vault' else 'idle'
  sample_frame=frame/length*produced['walk'].frame_range[1] if name=='carry_walk' else frame if name=='vault' else frame%48
  pose=reset_from(clip,sample_frame);restore(pose)
  for side,sign in [('Left',1),('Right',-1)]:
   if name in ['climb','hang']:
    phase=frame/length*2*math.pi+(0 if sign==1 else math.pi);reach=0 if name=='hang' else math.sin(phase)
    limb(side,'Arm','ForeArm','Hand',(sign*.22,-.3,1.57+reach*.17),(sign*.65,-.2,1.3));aim(side+'Hand',(sign*.22,-.4,1.57+reach*.17))
    limb(side,'UpLeg','Leg','Foot',(sign*.13,-.24,.24-reach*.15),(sign*.17,-.8,.65))
   else:
    lowering=(math.sin(frame/length*math.pi)*.2 if name=='drop' else 0);z=1.1-lowering
    limb(side,'Arm','ForeArm','Hand',(sign*.29,-.23,z+.03),(sign*.40,.1,.8));aim(side+'Hand',(sign*.28,-.35,z))
  target.animation_data.action=action
  for p in target.pose.bones:
   p.rotation_mode='QUATERNION';p.keyframe_insert('rotation_quaternion',frame=frame,group=p.name);p.keyframe_insert('location',frame=frame,group=p.name)
 action.use_fake_user=True;produced[name]=action;print('AUTHORED',name,length,flush=True)
# Camera-only arm roots sit below the eye, as in a dedicated first-person rig.
# Keep authored anatomy/UVs; solve hands to the same cargo instead of exposing shoulder cuts.
for clip in ['carry', 'carry_walk', 'pickup', 'drop', 'operate']:
 action=bpy.data.actions.new('fp_'+clip)
 length=32 if clip=='carry_walk' else 48
 for frame in range(length+1):
  pose=reset_from('carry_walk' if clip=='carry_walk' else 'carry',frame);restore(pose)
  for side,sign in [('Left',1),('Right',-1)]:
   arm=target.pose.bones['mixamorig:'+side+'Arm'];matrix=arm.matrix.copy();matrix.translation=Vector((sign*.28,.12,1.0));arm.matrix=matrix;bpy.context.view_layer.update()
   lower=math.sin(frame/length*math.pi)*.08 if clip in ['pickup','drop'] else 0
   limb(side,'Arm','ForeArm','Hand',(sign*.27,-.36,1.10-lower),(sign*.45,0,.72))
   aim(side+'Hand',(sign*.23,-.48,1.08-lower))
  target.animation_data.action=action
  for p in target.pose.bones:
   p.rotation_mode='QUATERNION';p.keyframe_insert('rotation_quaternion',frame=frame,group=p.name);p.keyframe_insert('location',frame=frame,group=p.name)
 action.use_fake_user=True;produced['fp_'+clip]=action
 print('FP_ROOT',clip,list(target.pose.bones['mixamorig:LeftArm'].head),flush=True)

# Dedicated first-person geometry shares the original mesh UVs, skeleton and materials.
import bmesh
for original,name in [(next(o for o in meshes if o.name=='WorkerSkin'),'FPHands'),(next(o for o in meshes if o.name=='FieldJacketAndTrousers'),'FPSleeves')]:
 clone=original.copy();clone.data=original.data.copy();clone.name=name;bpy.context.collection.objects.link(clone);meshes.append(clone)
 bm=bmesh.new();bm.from_mesh(clone.data);deform=bm.verts.layers.deform.active
 parts = ['Hand', 'ForeArm', 'Arm'] if name == 'FPSleeves' else ['Hand', 'ForeArm']
 ids={g.index for g in clone.vertex_groups if any(x in g.name for x in parts)}
 remove=[v for v in bm.verts if sum(v[deform].get(g,0) for g in ids)<.8]
 bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(clone.data);bm.free()

# Source meshes/rig and unused source animations are dev inputs only.
for o in list(bpy.data.objects):
 if o not in meshes and o!=target:bpy.data.objects.remove(o,do_unlink=True)
for a in list(bpy.data.actions):
 if a not in produced.values():bpy.data.actions.remove(a)
target.animation_data.action=produced['idle'];bpy.context.scene.frame_set(0)
# Measure the retargeted contact motion rather than guessing gait playback rates.
# Positive Blender Y is rearward: a planted foot moves that way in model space.
import statistics
metrics={}
for name in ['walk','jog','sprint','carry_walk']:
 action=produced[name];target.animation_data.action=action
 count=int(action.frame_range[1]);samples=[]
 for frame in range(count+1):
  bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
  samples.append([target.pose.bones['mixamorig:'+side+'Foot'].head.copy() for side in ['Left','Right']])
 speeds=[]
 for side in range(2):
  heights=sorted(row[side].z for row in samples);threshold=heights[len(heights)//3]+.01
  for a,b in zip(samples,samples[1:]):
   speed=(b[side].y-a[side].y)*24
   if a[side].z<=threshold and b[side].z<=threshold and speed>.1:speeds.append(speed)
 assert speeds, ('Missing stance samples',name)
 metrics[name]={'duration_seconds':count/24,'stance_speed_mps':round(statistics.median(speeds),5),'stance_samples':len(speeds)}
(ROOT/'assets/characters/locomotion_metrics.json').write_text(json.dumps(metrics,indent=2)+'\n')
print('GAIT_METRICS',metrics,flush=True)
target.animation_data.action=produced['idle'];bpy.context.scene.frame_set(0)
# Limit resident textures to 2K; packed GLB includes original authored UV data.
for im in bpy.data.images:
 if max(im.size)>2048:
  ratio=2048/max(im.size);im.scale(int(im.size[0]*ratio),int(im.size[1]*ratio))
# Export only the production model. GLTF rotates Blender -Y forward to Godot +Z.
bpy.ops.object.select_all(action='DESELECT')
for o in meshes+[target]:o.select_set(True)
path=str(ROOT/'assets/characters');pathlib.Path(path).mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=path+'/railway_survivor.glb',export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_anim_slide_to_zero=True,export_def_bones=True,export_all_influences=False)
bpy.ops.wm.save_as_mainfile(filepath=str(BUILD/'worker-animated.blend'))
