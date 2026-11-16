import os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
SOURCES = Path(os.environ.get("LTO_SOURCE_DIR", "/tmp/last-train-out-assets/sources"))
MPFB = Path(os.environ.get("LTO_MPFB_SOURCE", "/tmp/last-train-out-assets/mpfb2"))
HUMAN_DATA = Path(os.environ.get("LTO_MAKEHUMAN_DATA", "/tmp/last-train-out-assets/makehuman"))
BUILD = Path(os.environ.get("LTO_BUILD_DIR", "/tmp/last-train-out-assets/build"))
BUILD.mkdir(parents=True, exist_ok=True)
import bpy,pathlib,json
from mathutils import Vector
src=SOURCES/'polyhaven';out=ROOT/'assets/props';out.mkdir(exist_ok=True);meta=[]
for file in sorted(src.glob('*/*.gltf')):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(file));objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 if file.parent.name=='industrial_caged_sconce':
  for o in objects:
   if o.name!='industrial_caged_sconce_a':bpy.data.objects.remove(o,do_unlink=True)
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 if file.parent.name=='vintage_suitcase':
  for o in objects:
   if '_02_' in o.name:bpy.data.objects.remove(o,do_unlink=True)
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 points=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box];lo=Vector([min(v[i] for v in points) for i in range(3)]);hi=Vector([max(v[i] for v in points) for i in range(3)])
 # Ground and centre at the authored physical scale. No collider exported.
 offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 for o in objects:
  matrix=o.matrix_world.copy();o.parent=None;o.matrix_world=matrix;o.location-=offset
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
 bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 # Join by material so an instanced prop uses a handful of draw calls.
 bpy.ops.object.join();o=bpy.context.object;o.name=file.parent.name
 tris=sum(len(p.vertices)-2 for p in o.data.polygons)
 budget={'wooden_crate_01':2200,'wooden_military_crate':3000,'brass_blowtorch':2000,'small_oil_can_01':1800,'industrial_caged_sconce':4000,'caged_hanging_light':6000,'industrial_storage_cart':7000,'vintage_suitcase':6000,'hand_truck':7000,'wooden_military_crate':6500}.get(file.parent.name,10000)
 if tris>budget:
  dec=o.modifiers.new('Game mesh budget','DECIMATE');dec.ratio=budget/tris;bpy.ops.object.modifier_apply(modifier=dec.name)
 bpy.ops.export_scene.gltf(filepath=str(out/(file.parent.name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
 meta.append({'id':file.parent.name,'size_m':list(hi-lo),'vertices':len(o.data.vertices),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)})
 print('PROP',meta[-1],flush=True)
(out/'mesh_metrics.json').write_text(json.dumps(meta,indent=2))
