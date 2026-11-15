"""Fit licensed MakeHuman anatomy, clothing and skin using MPFB. See docs/ASSET_PIPELINE.md."""
import os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
SOURCES = Path(os.environ.get("LTO_SOURCE_DIR", "/tmp/last-train-out-assets/sources"))
MPFB = Path(os.environ.get("LTO_MPFB_SOURCE", "/tmp/last-train-out-assets/mpfb2"))
HUMAN_DATA = Path(os.environ.get("LTO_MAKEHUMAN_DATA", "/tmp/last-train-out-assets/makehuman"))
BUILD = Path(os.environ.get("LTO_BUILD_DIR", "/tmp/last-train-out-assets/build"))
BUILD.mkdir(parents=True, exist_ok=True)
import sys, bpy, pathlib
sys.path.insert(0,str(MPFB/'src'))
base=HUMAN_DATA;base.mkdir(exist_ok=True)
original=bpy.utils.extension_path_user
bpy.utils.extension_path_user=lambda package, *a, **kw: str(base) if package=='mpfb' else original(package,*a,**kw)
resource=bpy.utils.resource_path
bpy.utils.resource_path=lambda kind: str(BUILD/"blender-user") if kind=="USER" else resource(kind)
import addon_utils
addon_utils.enable('mpfb',default_set=True)
from mpfb.services.humanservice import HumanService
from mpfb.services.targetservice import TargetService
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
macro=TargetService.get_default_macro_info_dict()
macro.update({'gender':1.0,'age':.55,'muscle':.5,'weight':.5,'height':.5})
body=HumanService.create_human(macro_detail_dict=macro)
rig=HumanService.add_builtin_rig(body,'mixamo')

from mathutils import Vector
from pathlib import Path
D=HUMAN_DATA/'data'
body.name='WorkerSkin';rig.name='WorkerRig'
HumanService.set_character_skin(str(D/'skins/middleage_caucasian_male/middleage_caucasian_male.mhmat'),body,skin_type='MAKESKIN')
clothes=HumanService.add_mhclo_asset(str(D/'clothes/male_casualsuit05/male_casualsuit05.mhclo'),body,subdiv_levels=1)
clothes.name='FieldJacketAndTrousers'
boots=HumanService.add_mhclo_asset(str(D/'clothes/toigo_ankle_boots_male/toigo_ankle_boots_male.mhclo'),body,subdiv_levels=1)
boots.name='LeatherWorkBoots'
eyes=HumanService.add_mhclo_asset(str(D/'eyes/high-poly/high-poly.mhclo'),body,asset_type='Eyes',subdiv_levels=0)
eyes.name='Eyes'
brows=HumanService.add_mhclo_asset(str(D/'eyebrows/eyebrow001/eyebrow001.mhclo'),body,asset_type='Eyebrows',subdiv_levels=0)
brows.name='Eyebrows'
hair=HumanService.add_mhclo_asset(str(D/'hair/short04/short04.mhclo'),body,asset_type='Hair',subdiv_levels=1)
hair.name='ShortHair'
lashes=HumanService.add_mhclo_asset(str(D/'eyelashes/eyelashes01/eyelashes01.mhclo'),body,asset_type='Eyelashes',subdiv_levels=0)
lashes.name='Eyelashes'
# Standard glTF PBR materials: preserve authored UVs and source image data.
def material(obj,name,diffuse,normal=None,rough=.7,alpha=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=rough
 def tex(path):
  t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(path),check_existing=True);return t
 d=tex(diffuse);l.new(d.outputs['Color'],p.inputs['Base Color'])
 if alpha:
  l.new(d.outputs['Alpha'],p.inputs['Alpha']);m.surface_render_method='DITHERED'
 if normal:
  t=tex(normal);t.image.colorspace_settings.name='Non-Color';nm=n.new('ShaderNodeNormalMap');l.new(t.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],p.inputs['Normal'])
 obj.data.materials.clear();obj.data.materials.append(m)
material(body,'Middle-aged worker skin',D/'skins/middleage_caucasian_male/middleage_lightskinned_male_diffuse.png',D/'skins/mindfront_skin_male_african_middleage/skin_male_african_middleage_NRM.png',.64)
material(clothes,'Worn field jacket denim and leather',D/'clothes/male_casualsuit05/male_casualsuit05_diffuse.png',D/'clothes/male_casualsuit05/male_casualsuit05_normal.png',.82)
material(boots,'Worn leather work boots',D/'clothes/toigo_ankle_boots_male/BootsAnkleM.png',D/'clothes/toigo_ankle_boots_male/BootsAnkle-norm.png',rough=.76)
material(eyes,'Brown iris and sclera',D/'eyes/materials/brown_eye.png',rough=.17,alpha=True)
material(brows,'Authored eyebrow cards',D/'eyebrows/eyebrow001/eyebrow001.png',rough=.9,alpha=True)
material(hair,'Short cropped hair',D/'hair/short04/short04_diffuse.png',rough=.86,alpha=True)
material(lashes,'Authored eyelash cards',D/'eyelashes/eyelashes01/eyelashes01.png',rough=.9,alpha=True)
# Bake morph shape and masks. Leave skinning live. One subdivision retains fingers/face.
for obj in [body,clothes,eyes,brows,hair,boots,lashes]:
 bpy.context.view_layer.objects.active=obj;obj.select_set(True)
 if obj.data.shape_keys:bpy.ops.object.shape_key_remove(all=True,apply_mix=True)
 if obj==eyes:
  sub=obj.modifiers.new('Iris curvature','SUBSURF');sub.levels=1
 if obj==clothes:
  sub=obj.modifiers.new('Garment curvature','SUBSURF');sub.levels=1
 if obj==body:
  sub=obj.modifiers.new('Facial topology refinement','SUBSURF');sub.levels=1
 for mod in list(obj.modifiers):
  if obj == body and mod.type == 'MASK' and mod.name.startswith('Delete.'):
   obj.modifiers.remove(mod);continue
  if mod.type!='ARMATURE':
   if mod.type == 'SUBSURF' and mod.levels == 0:
    obj.modifiers.remove(mod);continue
   if mod.show_viewport:
    try:bpy.ops.object.modifier_apply(modifier=mod.name)
    except RuntimeError:
     print('INACTIVE',obj.name,mod.name,mod.type);obj.modifiers.remove(mod)
   else:obj.modifiers.remove(mod)
 for f in obj.data.polygons:f.use_smooth=True
 # MPFB stores some valid bone weights with totals below/above one. Blender
 # and glTF normalize these for skinning, but geometric masks must use the
 # same normalized values or they cut holes through wrists, palms and cuffs.
 bone_ids={g.index for g in obj.vertex_groups if g.name in rig.data.bones}
 for vertex in obj.data.vertices:
  influences=[(g.group,g.weight) for g in vertex.groups if g.group in bone_ids]
  total=sum(weight for _,weight in influences)
  if total>0:
   for index,weight in influences:obj.vertex_groups[index].add([vertex.index],weight/total,'REPLACE')
 obj.select_set(False)
 print('MESH',obj.name,len(obj.data.vertices),len(obj.data.polygons),'bounds',obj.dimensions[:])
import bmesh
bm=bmesh.new();bm.from_mesh(body.data);deform=bm.verts.layers.deform.active
hand_ids={g.index for g in body.vertex_groups if any(part in g.name for part in ['Hand', 'ForeArm'])}
# Keep face/neck, the open collar, and the forearms needed by the FP mesh.
# Skin beneath the opaque jacket/trousers otherwise adds tens of thousands of
# invisible animated triangles. This is a visual mask, never body collision.
remove=[v for v in bm.verts if not (v.co.z>1.43 or (v.co.z>1.24 and abs(v.co.x)<.13 and v.co.y<0) or any(v[deform].get(g,0)>.12 for g in hand_ids))]
bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(body.data);bm.free()
# Presentation-only preview, never included in exported character.
bpy.ops.wm.save_as_mainfile(filepath=str(BUILD/'worker-source.blend'))
if '--no-render' in sys.argv:sys.exit(0)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.render.resolution_x=900;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.world.color=(.22,.22,.22)
for name,loc,energy,size in [('Key',(-3,-4,4),450,4),('Fill',(3,-2,2),200,3),('Rim',(1,2,3),400,3)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Inspect');cam=bpy.data.objects.new('Inspect',data);scene.collection.objects.link(cam);scene.camera=cam;cam.location=(0,-3.5,1.2);cam.rotation_euler=(Vector((0,0,.9))-cam.location).to_track_quat('-Z','Y').to_euler();data.lens=55
scene.render.filepath=str(BUILD/'worker-preview.png');bpy.ops.render.render(write_still=True)
