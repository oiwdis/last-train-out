import os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
SOURCES = Path(os.environ.get("LTO_SOURCE_DIR", "/tmp/last-train-out-assets/sources"))
MPFB = Path(os.environ.get("LTO_MPFB_SOURCE", "/tmp/last-train-out-assets/mpfb2"))
HUMAN_DATA = Path(os.environ.get("LTO_MAKEHUMAN_DATA", "/tmp/last-train-out-assets/makehuman"))
BUILD = Path(os.environ.get("LTO_BUILD_DIR", "/tmp/last-train-out-assets/build"))
BUILD.mkdir(parents=True, exist_ok=True)
import bpy,bmesh,math,pathlib,json
from mathutils import Vector,Matrix
bpy.ops.wm.open_mainfile(filepath=str(SOURCES/'roland_schuller_steam_locomotive_2k.blend'))
out=ROOT/'assets/train';out.mkdir(exist_ok=True);pbr=ROOT/'assets/pbr'
# Baked source topology; adapt the rear cab to the existing walk-through footprint.
deps=bpy.context.evaluated_depsgraph_get();source=list(bpy.context.scene.objects);meshes=[]
# These source pieces form the static coupling/connecting rods and crank pins.
# Runtime TrainMechanics replaces them with quartered slider-crank motion.
linkages={'Cube','Cube.005','Cube.018','Cube.019','Cube.021','Cube.023',
          'Cylinder','Cylinder.005','Cylinder.017','Cylinder.023'}
linkages.update({'End'+('.%03d'%i if i else '') for i in range(11)})
for obj in source:
 if obj.name in linkages:continue
 if obj.type not in ['MESH','CURVE','FONT'] or obj.name.startswith(('Text','path')):continue
 mesh=bpy.data.meshes.new_from_object(obj.evaluated_get(deps),depsgraph=deps);matrix=obj.matrix_world.copy();new=bpy.data.objects.new(obj.name+'__game',mesh);bpy.context.collection.objects.link(new)
 for v in mesh.vertices:
  w=matrix@v.co;v.co=Vector((-w.x*.7+.6,-w.y*.7,w.z*.7+.015))
 # Remove the original inaccessible bunker/cab while retaining suspension below it.
 bm=bmesh.new();bm.from_mesh(mesh);remove=[v for v in bm.verts if v.co.x < -1.0 and v.co.z>1.04];bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(mesh);bm.free()
 if len(mesh.polygons)==0:bpy.data.objects.remove(new,do_unlink=True);continue
 meshes.append(new)
for obj in source:bpy.data.objects.remove(obj,do_unlink=True)
# Source procedural Cycles finishes are replaced by shared real scanned PBR maps.
palette={'Black':(.065,.08,.075),'Black Metal Paint':(.09,.115,.105),'Black.001':(.025,.03,.028),'Blitzgelb':(.56,.39,.09),'Dim Light':(.7,.57,.32),'Lighter Metal':(.32,.34,.34),'Old Metal':(.2,.23,.23),'PitchBlack':(.016,.019,.02),'Red':(.24,.045,.028),'rusty':(.27,.16,.08),'Shiny Chrome':(.48,.5,.5),'Shiny Chrome Reflective':(.48,.5,.5),'White Marker':(.55,.52,.41),'White Text':(.55,.52,.41),'Burn wood':(.035,.03,.025),'Wood Black UA':(.1,.08,.06)}
materials={}
def mat(name):
 if name in materials:return materials[name]
 color=palette.get(name,(.08,.1,.09));m=bpy.data.materials.new('LTO '+name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;bs=n.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=.65;bs.inputs['Roughness'].default_value=.65
 if 'glass' in name.lower():
  bs.inputs['Base Color'].default_value=(.14,.23,.27,1);bs.inputs['Roughness'].default_value=.22;bs.inputs['Metallic'].default_value=.35
 else:
  base='rusty_painted_metal' if name not in ['Burn wood','Wood Black UA'] else 'wood_planks_grey'
  def tex(kind):
   t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(pbr/(base+'_'+kind+'.jpg')),check_existing=True);return t
  d=tex('albedo');mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*color,1);l.new(d.outputs['Color'],mix.inputs[1]);l.new(mix.outputs[0],bs.inputs['Base Color'])
  # glTF does not export arbitrary shader math: bake the constant tint into a small image.
  im=d.image.copy();im.name='LTO_'+name+'_paint';pixels=list(im.pixels)
  for i in range(0,len(pixels),4):
   for c in range(3):pixels[i+c]*=color[c]**.4545
  im.pixels=pixels;im.pack();d.image=im;l.new(d.outputs['Color'],bs.inputs['Base Color'])
  rough=tex('roughness');rough.image.colorspace_settings.name='Non-Color';l.new(rough.outputs['Color'],bs.inputs['Roughness']);normal=tex('normal');normal.image.colorspace_settings.name='Non-Color';nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.3;l.new(normal.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],bs.inputs['Normal'])
 materials[name]=m;return m
for o in meshes:
 old=[s.material.name if s.material else 'Black' for s in o.material_slots]
 o.data.materials.clear()
 for name in old:o.data.materials.append(mat(name))
 if not old:o.data.materials.append(mat('Black'))
 # Metre-scaled planar UV projection per face; repeats never stretch along the boiler.
 uv=o.data.uv_layers.new(name='GameUV')
 for p in o.data.polygons:
  axis=max(range(3),key=lambda i:abs(p.normal[i]));a,b=[i for i in range(3) if i!=axis]
  for li in p.loop_indices:
   co=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(co[a]*1.2,co[b]*1.2)
 o.data.uv_layers.active=uv
 # Make the chosen layer the render layer, rather than any inherited source UV.
 for layer in list(o.data.uv_layers):
  if layer!=uv:o.data.uv_layers.remove(layer)
# Consolidate static geometry; wheels keep real axle pivots for speed-driven rotation.
wheelgroups={};static=[]
for o in meshes:
 if o.name.startswith('Wheel') or o.name == 'ScrewHead.027__game':
  centre=sum((v.co for v in o.data.vertices),Vector())/len(o.data.vertices);key=(round(centre.x,1),round(centre.y,1));wheelgroups.setdefault(key,[]).append(o)
 else:static.append(o)
def join(objects,name,budget):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 tris=sum(len(p.vertices)-2 for p in o.data.polygons)
 if tris>budget:
  d=o.modifiers.new('Game topology budget','DECIMATE');d.ratio=budget/tris;bpy.ops.object.modifier_apply(modifier=d.name)
 return o
body=join(static,'LocomotiveBody',145000)
for i,objects in enumerate(wheelgroups.values()):
 o=join(objects,'DrivingWheel%02d'%i,5000);lo=Vector([min(v.co[a] for v in o.data.vertices) for a in range(3)]);hi=Vector([max(v.co[a] for v in o.data.vertices) for a in range(3)]);centre=(lo+hi)/2
 for v in o.data.vertices:v.co-=centre
 o.location=centre;o['wheel_radius']=(hi.z-lo.z)/2
print('TRAIN_GAME',[(o.name,len(o.data.polygons)) for o in bpy.context.scene.objects if o.type=='MESH'],flush=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.gltf(filepath=str(out/'steam_locomotive.glb'),export_format='GLB',export_animations=False,export_cameras=False,export_lights=False)
bpy.ops.wm.save_as_mainfile(filepath=str(BUILD/'train-game.blend'))
