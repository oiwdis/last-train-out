"""Original fitted carriage/cab finishing meshes; dimensions in Godot metres."""
import bpy,math,pathlib
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[2];OUT=ROOT/'assets/train';OUT.mkdir(exist_ok=True)
def xyz(v):return Vector((v[0],-v[2],v[1]))
def material(name,color,metal=0,texture=None):
 m=bpy.data.materials.new(name);m.use_nodes=True;bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=.65
 if texture:
  n=m.node_tree.nodes;l=m.node_tree.links
  for kind,socket in [('albedo','Base Color'),('roughness','Roughness'),('normal',None)]:
   t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(ROOT/'assets/pbr'/(texture+'_'+kind+'.jpg')),check_existing=True)
   if kind!='albedo':t.image.colorspace_settings.name='Non-Color'
   if socket:l.new(t.outputs['Color'],bs.inputs[socket])
   else:
    nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.35;l.new(t.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],bs.inputs['Normal'])
 return m
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
paint=material('Weathered painted carriage steel',(.1,.14,.13),.55,'green_metal_rust');steel=material('Black oxide hardware',(.055,.065,.065),.75);brass=material('Tarnished brass',(.43,.28,.08),.7);wood=material('Worn timber joinery',(.2,.15,.09),0,'wood_planks_grey');rubber=material('Window rubber seals',(.012,.015,.014));pale=material('Instrument enamel',(.66,.63,.52));glass=material('Smoked window glass',(.14,.21,.23),.25);glass.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.18;glass.surface_render_method='DITHERED'
def box(name,p,size,mat,bevel=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(p));o=bpy.context.object;o.name=name;o.dimensions=xyz((size[0],size[1],-size[2]));bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 if bevel:
  m=o.modifiers.new('Manufactured edges','BEVEL');m.width=bevel;m.segments=2;bpy.ops.object.modifier_apply(modifier=m.name)
 return o
def tube(name,points,r,mat):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=2;c.bevel_depth=r;c.bevel_resolution=2;s=c.splines.new('POLY');s.points.add(len(points)-1)
 for p,v in zip(s.points,points):p.co=(*xyz(v),1)
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(mat);return o
def ring(name,p,w,h,mat,r=.018):
 x,y,z=p;points=[];rad=min(.09,w/4,h/4)
 for cx,cy,start in [(x+w/2-rad,y+h/2-rad,0),(x-w/2+rad,y+h/2-rad,90),(x-w/2+rad,y-h/2+rad,180),(x+w/2-rad,y-h/2+rad,270)]:
  for i in range(7):a=math.radians(start+i*15);points.append((cx+math.cos(a)*rad,cy+math.sin(a)*rad,z))
 points.append(points[0]);return tube(name,points,r,mat)
def rivet(p,side=1):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.018,location=xyz(p));o=bpy.context.object;o.name='Rivet';o.scale=(1,.35,1);o.data.materials.append(steel)
def roof(center,length):
 verts=[];faces=[]
 for x in [center-length/2,center+length/2]:
  for i in range(25):z=-1.4+i*2.8/24;y=3.52+.20*(1-(z/1.4)**2);verts.append(xyz((x,y,z)))
 for i in range(24):faces.append((i,i+1,26+i,25+i))
 mesh=bpy.data.meshes.new('Rolled steel roof');mesh.from_pydata(verts,[],faces);o=bpy.data.objects.new('Rolled steel roof',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(paint)
 for p in mesh.polygons:p.use_smooth=True
 solid=o.modifiers.new('Roof thickness','SOLIDIFY');solid.thickness=.035
 for x in range(math.ceil(center-length/2),math.floor(center+length/2)+1):
  tube('Roof seam',[(x,3.53+.20*(1-((-1.4+i*2.8/24)/1.4)**2),-1.4+i*2.8/24) for i in range(25)],.016,steel)
 for side in [-1,1]:tube('Rain gutter',[(center-length/2,3.51,side*1.38),(center+length/2,3.51,side*1.38)],.027,steel)
def export(name):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.convert(target='MESH');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 # Tile wood and scanned metal at a fixed world scale.
 for o in bpy.context.selected_objects:
  if o.type!='MESH':continue
  uv=o.data.uv_layers.new(name='MetreUV')
  for p in o.data.polygons:
   axis=max(range(3),key=lambda i:abs(p.normal[i]));a,b=[i for i in range(3) if i!=axis]
   for li in p.loop_indices:
    v=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(v[a]*1.2,v[b]*1.2)
  for old in list(o.data.uv_layers):
   if old!=uv:o.data.uv_layers.remove(old)
 bpy.context.view_layer.objects.active=next(o for o in bpy.context.selected_objects if o.type=='MESH');bpy.ops.object.join();bpy.context.object.name=name
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False)
 bpy.ops.object.delete(use_global=False)
for crew in [False,True]:
 center=0 if crew else -2.6;length=6.8 if crew else 3.2;count=6 if crew else 3;roof(center,length+.3)
 for side in [-1,1]:
  z=side*1.26
  box('Riveted lower side',(center,1.43,z),(length,.86,.1),paint);box('Upper body band',(center,3.24,z),(length,.52,.1),paint)
  for i in range(count):
   x=center-length/2+(i+.5)*length/count;w=length/count-.14
   box('Window stile',(x+w/2+.045,2.39,z),(.09,1.1,.1),paint)
   for s in [-1,1]:
    ring('Rounded window seal',(x,2.39,z+s*.058),w,.98,rubber,.021);ring('Brass retaining frame',(x,2.39,z+s*.069),w-.045,.935,brass,.009)
   box('Window pane',(x,2.39,z),(w-.06,.91,.018),glass,0)
   for y in [1.1,1.78,3.05,3.44]:
    for dx in [-w*.38,0,w*.38]:rivet((x+dx,y,z+side*.065))
  tube('Waist seam',[(center-length/2,1.9,z+side*.065),(center+length/2,1.9,z+side*.065)],.014,steel)
  # Interior panelling, sill, grab rails and floor edge trim.
  box('Interior wainscot',(center,1.48,side*1.19),(length,.82,.035),wood)
  box('Window sill',(center,1.87,side*1.18),(length,.045,.17),wood)
  tube('Interior handrail',[(center-length/2+.2,3.02,side*1.1),(center+length/2-.2,3.02,side*1.1)],.018,brass)
 for end in [-1,1]:
  x=center+end*length/2
  if not crew and end>0:continue
  for side in [-1,1]:
   box('Gangway jamb',(x,2.1,side*.98),(.13,2.2,.64),paint)
   tube('Boarding grab rail',[(x+end*.1,1.3,side*.84),(x+end*.1,2.8,side*.84)],.023,brass)
  box('Gangway lintel',(x,3.36,0),(.13,.28,2.6),paint)
 for z in [-1.15,1.15]:
  box('Underframe girder',(center,.77,z),(length+.6,.25,.12),steel)
  tube('Brake line',[(center-length/2,.65,z),(center+length/2,.65,z)],.023,brass)
 for i in range(math.ceil(length/.18)):
  step=length/math.ceil(length/.18);box('Floorboard',(center-length/2+(i+.5)*step,.985,0),(step-.006,.03,2.45),wood,.003)
 for axle in [-2.4,2.4] if crew else [-3.5]:
  for side in [-1,1]:
   tube('Suspension spring',[(axle-.3+i*.012,.66+.085*math.sin(i*math.pi/5),side*1.06+.085*math.cos(i*math.pi/5)) for i in range(51)],.012,steel)
 if crew:
  for side in [-1,1]:
   for x in [-1.8,1.8]:
    for i in range(5):box('Seat board',(x,1.43,side*(.76+i*.09)),(1.65,.12,.078),wood)
    for i in range(4):box('Backrest board',(x,1.54+i*.14,side*1.15),(1.65,.115,.065),wood)
    for leg in [-.65,.65]:tube('Cast bench leg',[(x+leg,1.02,side*1.1),(x+leg,1.36,side*1.05),(x+leg,1.36,side*.77),(x+leg,1.02,side*.72)],.035,steel)
 else:
  # Curved firebox cover, service handles and brass pipework surround live controls.
  box('Firebox rear plate',(-1.24,2.12,0),(.18,2.15,2.15),steel,.06)
  for z in [-.96,.96]:
   tube('Injector line',[(-1.5,1.1,z),(-1.5,2.7,z),(-1.5,2.9,z*.5)],.033,brass)
  for z in [-.63,0,.63]:
   # Faces remain in the original live-control sight lines; ticks are raised enamel insets.
   for radius,depth,mat in [(.155,.065,brass),(.126,.075,pale)]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=40,radius=radius,depth=depth,location=xyz((-1.65,2.52,z)),rotation=(0,math.pi/2,0));bpy.context.object.data.materials.append(mat)
   for i in range(13):
    a=math.radians(-130+i*260/12);tube('Pressure graduation',[(-1.7,2.52+math.cos(a)*.096,z+math.sin(a)*.096),(-1.7,2.52+math.cos(a)*.115,z+math.sin(a)*.115)],.003,steel)
   tube('Instrument needle',[(-1.705,2.52,z),(-1.705,2.59,z-.04)],.004,steel)
  tube('Firebox hatch',[(-1.5,1.54+math.sin(i*math.tau/40)*.22,math.cos(i*math.tau/40)*.28) for i in range(41)],.018,brass) # Decorative rim; live controls stay separate.
 export('crew_car_finish' if crew else 'locomotive_cab_finish')
# Hinged metal door with recessed panels, gasket, hinges and a rounded pull handle.
box('Door skin',(.66,1.1,0),(1.32,2.2,.055),paint)
for y,h in [(.6,.84),(1.59,.65)]:
 ring('Pressed panel rim',(.66,y,.035),1.12,h,steel,.012)
 box('Inset panel',(.66,y,.032),(1.05,h-.07,.022),wood if y<1 else glass,.008)
for y in [.35,1.75]:
 tube('Hinge pin',[(.025,y-.1,0),(.025,y+.1,0)],.022,brass)
 tube('Pull handle',[(1.15,.95,.06),(1.15,.95,.12),(1.15,1.17,.12),(1.15,1.17,.06)],.017,brass)
export('carriage_door')

# Functional control fixture; separate Handle node pivots with each live command.
box('Mounting plate',(.035,0,0),(.025,.19,.16),steel,.012)
for y in [-.065,.065]:
 for z in [-.05,.05]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.012,depth=.008,location=xyz((.017,y,z)),rotation=(0,math.pi/2,0));bpy.context.object.data.materials.append(brass)
bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=bpy.context.selected_objects[0];bpy.ops.object.join();base=bpy.context.object;base.name='Mount'
bpy.ops.object.select_all(action='DESELECT')
tube('Regulator arm',[(.01,0,0),(-.07,.015,0),(-.19,.15,0)],.014,brass)
tube('Grip',[(-.19,.15,-.06),(-.19,.15,.06)],.026,wood)
bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=.04,depth=.09,location=xyz((0,0,0)),rotation=(math.pi/2,0,0));bpy.context.object.data.materials.append(steel)
for o in bpy.context.scene.objects:o.select_set(o!=base)
bpy.ops.object.convert(target='MESH');bpy.context.view_layer.objects.active=next(o for o in bpy.context.selected_objects);bpy.ops.object.join();lever=bpy.context.object;lever.name='Handle';bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.gltf(filepath=str(OUT/'control_lever.glb'),export_format='GLB',use_selection=True,export_animations=False)
