"""Original Last Train Out models. Run: blender -b --python tools/build_original_models.py.
Metres; inputs use Godot's X/right, Y/up, Z/front coordinates. No external geometry.
"""
import bpy, math, pathlib
from mathutils import Vector
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
OUT.mkdir(parents=True, exist_ok=True)
def v(p): return Vector((p[0], -p[2], p[1]))
def material(name, color, metallic=0, rough=.6):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=metallic;bs.inputs['Roughness'].default_value=rough
    return m
iron=material('Blackened iron',(.075,.09,.095),.75,.48)
steel=material('Machined steel',(.27,.3,.31),.85,.3)
brass=material('Aged brass',(.38,.26,.11),.75,.4)
rust=material('Oxide',(.25,.12,.065),.4,.85)
coat=material('Waxed railway coat',(.12,.17,.16),0,.86)
pants=material('Worn wool',(.09,.105,.115),0,.94)
leather=material('Oiled leather',(.07,.045,.025),0,.7)
skin=material('Skin',(.43,.275,.19),0,.68)
hair=material('Hair',(.075,.055,.035),0,.9)
white=material('Porcelain',(.72,.69,.59),0,.4)

def reset():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def assign(o,name,mat,parent=None):
    o.name=name;o.data.materials.append(mat)
    if parent: o.parent=parent
    return o
def box(name,at,size,mat,bevel=.025,parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=v(at));o=bpy.context.object;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Rounded fabricated edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
        mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=mod.name)
    return assign(o,name,mat,parent)
def sphere(name,at,size,mat,parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=v(at));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for p in o.data.polygons:p.use_smooth=True
    return assign(o,name,mat,parent)
def rod(name,a,b,r,mat,r2=None,vertices=20,parent=None):
    d=v(b)-v(a);bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(v(a)+v(b))/2)
    o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
    return assign(o,name,mat,parent)
def ring(name,at,r,t,mat,axis='x',parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=r,minor_radius=t,major_segments=40,minor_segments=8,location=v(at));o=bpy.context.object
    if axis=='x':o.rotation_euler.y=math.pi/2
    if axis=='z':o.rotation_euler.x=math.pi/2
    for p in o.data.polygons:p.use_smooth=True
    return assign(o,name,mat,parent)
def empty(name,at,parent=None):
    o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=v(at);o.parent=parent;return o
def loft(name,rings,mat,parent=None):
    n=24;verts=[]
    for y,rx,rz,zoff in rings:
        for i in range(n):
            a=2*math.pi*i/n;verts.append(v((math.cos(a)*rx,y,math.sin(a)*rz+zoff)))
    faces=[tuple(range(n-1,-1,-1))]
    for j in range(len(rings)-1):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    faces.append(tuple((len(rings)-1)*n+i for i in range(n)))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    for p in mesh.polygons:p.use_smooth=True
    return assign(o,name,mat,parent)
def join_by_parent():
    parents={o.parent for o in list(bpy.context.scene.objects) if o.type=='MESH'}
    for parent in parents:
        objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==parent]
        if not objects:continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name=(parent.name if parent else 'Structure')+'_Mesh'
def export(name):
    join_by_parent()
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
    print('EXPORTED',name,sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH'))

reset()
# Full-size steam machinery: rolled boiler, flanges, rivets, valve pipes and fittings.
rod('Boiler',(-1,2.02,0),(4.2,2.02,0),.98,iron,vertices=64)
for x in [-.8,.1,1.4,2.7,4.15]:
    ring('Boiler seam',(x,2.02,0),.985,.035,steel)
    for i in range(24):
        a=i*math.tau/24
        sphere('Flange rivet',(x,2.02+.992*math.cos(a),.992*math.sin(a)),(.023,.023,.023),steel)
rod('Smokebox cover',(4.21,2.02,0),(4.28,2.02,0),.86,iron,vertices=48)
ring('Door rim',(4.3,2.02,0),.8,.035,steel)
for z in [-.48,.48]:box('Hinge',(4.32,2.02,z),(.1,.34,.07),steel,.012)
rod('Handwheel stem',(4.32,2.02,0),(4.48,2.02,0),.04,brass)
ring('Handwheel',(4.48,2.02,0),.18,.025,brass)
for i in range(5):
    a=i*math.tau/5;rod('Spoke',(4.48,2.02,0),(4.48,2.02+.17*math.sin(a),.17*math.cos(a)),.018,brass)
rod('Chimney base',(3.5,2.85,0),(3.5,3.28,0),.38,iron,r2=.22)
rod('Chimney',(3.5,3.2,0),(3.5,3.9,0),.23,iron,r2=.32)
ring('Chimney lip',(3.5,3.9,0),.32,.045,steel,axis='y')
sphere('Steam dome',(1.25,3.05,0),(.38,.45,.38),iron)
for z in [-1.06,1.06]:
    rod('Steam pipe',(-.9,2.5,z),(3.65,2.5,z),.045,brass)
    for x in [-.7,1,2.8]:
        rod('Pipe support',(x,2.25,z*.87),(x,2.5,z),.03,steel)
    rod('Cylinder',(2.9,.78,z),(3.8,.78,z),.2,iron)
    rod('Piston rod',(-2.2,.53,z),(3.35,.53,z),.045,steel)
    for x in [-2.2,-.6,1,2.6]:
        sphere('Crank bearing',(x,.53,z),(.12,.12,.065),brass)
    box('Running plate',(1.4,1.48,z),(5.5,.08,.36),iron,.025)
for z in [-.8,.8]:
    rod('Buffer',(4.5,.74,z),(4.95,.74,z),.09,steel)
    rod('Buffer head',(4.94,.74,z),(5.02,.74,z),.23,iron)
rod('Headlamp shell',(4.15,2.85,0),(4.45,2.85,0),.19,brass)
rod('Headlamp lens',(4.45,2.85,0),(4.46,2.85,0),.155,white)
export('locomotive_machinery')

reset()
ring('Steel tyre',(0,0,0),.405,.045,steel,axis='z')
ring('Wheel rim',(0,0,0),.36,.045,iron,axis='z')
rod('Hub',(0,0,-.1),(0,0,.1),.115,steel)
for i in range(12):
    a=i*math.tau/12;rod('Cast spoke',(0,0,0),(.37*math.sin(a),.37*math.cos(a),0),.025,iron)
export('rail_wheel')

reset()
# Worker is 1.78 m tall, with articulated shoulders, elbows, hips and knees.
body=empty('Torso',(0,0,0))
loft('Coat',[(.69,.2,.13,0),(.76,.21,.145,0),(1.0,.19,.145,0),(1.19,.22,.15,0),(1.39,.26,.135,0),(1.46,.21,.12,0)],coat,body)
rod('Neck',(0,1.43,0),(0,1.57,0),.065,skin,parent=body)
sphere('Head',(0,1.645,.008),(.085,.115,.085),skin,body)
sphere('Jaw',(0,1.596,.025),(.066,.061,.065),skin,body)
sphere('Nose',(0,1.64,.09),(.018,.025,.027),skin,body)
for side in [-1,1]:
    sphere('Ear',(side*.083,1.64,0),(.017,.031,.018),skin,body)
    sphere('Eye',(side*.034,1.674,.079),(.014,.008,.004),white,body)
    sphere('Iris',(side*.034,1.674,.083),(.006,.006,.003),hair,body)
    box('Brow',(side*.034,1.688,.079),(.029,.006,.006),hair,.002,body)
sphere('Work cap',(0,1.744,.005),(.09,.044,.09),pants,body)
box('Cap peak',(0,1.731,.084),(.17,.009,.09),leather,.025,body)
for side in [-1,1]:
    box('Chest pocket',(side*.125,1.28,.148),(.115,.12,.018),coat,.012,body)
    box('Pocket flap',(side*.125,1.335,.162),(.125,.035,.01),pants,.007,body)
for y in [.8,.91,1.02,1.13,1.24,1.35]:sphere('Button',(0,y,.153),(.01,.01,.006),brass,body)
box('Belt',(0,.9,0),(.425,.038,.3),leather,.02,body)
box('Buckle',(0,.9,.159),(.045,.032,.009),brass,.006,body)
box('Satchel',(0,1.15,-.19),(.31,.38,.13),leather,.045,body)
for side in [-1,1]:
    label='L' if side<0 else 'R'
    leg=empty('Leg'+label,(side*.112,.87,0))
    loft('Trouser thigh',[(0,.097,.105,0),(-.14,.092,.102,.005),(-.31,.074,.08,.005),(-.41,.07,.075,.01)],pants,leg)
    knee=empty('Knee'+label,(0,-.4,0),leg)
    loft('Trouser calf',[(0,.07,.078,.01),(-.15,.072,.075,0),(-.29,.058,.06,0),(-.36,.054,.06,0)],pants,knee)
    box('Boot',(0,-.385,.045),(.14,.16,.27),leather,.038,knee)
    box('Sole',(0,-.45,.048),(.145,.025,.278),iron,.012,knee)
    for j in range(4):box('Lace',(0,-.34+j*.021,.128),(.07,.007,.009),pants,.002,knee)
    arm=empty('Arm'+label,(side*.245,1.405,0))
    loft('Coat sleeve',[(0,.082,.086,0),(-.1,.078,.084,0),(-.22,.061,.067,0),(-.29,.058,.06,.012)],coat,arm)
    elbow=empty('Elbow'+label,(0,-.285,.01),arm)
    loft('Lower sleeve',[(0,.058,.065,0),(-.13,.059,.062,.015),(-.25,.046,.046,.025)],coat,elbow)
    box('Glove palm',(0,-.285,.033),(.085,.105,.05),leather,.023,elbow)
    for finger in range(4):rod('Glove finger',(-.03+finger*.02,-.31,.032),(-.03+finger*.02,-.373,.04),.009,leather,parent=elbow,vertices=8)
    rod('Thumb',(side*.038,-.265,.033),(side*.06,-.31,.06),.014,leather,parent=elbow,vertices=10)
export('rail_worker')

reset()
box('Soft edged unit',(0,0,0),(1,1,1),steel,.04)
export('beveled_box')

reset()
loft('Canvas sack',[(0,.17,.13,0),(.06,.23,.18,0),(.3,.245,.19,0),(.52,.19,.15,.01),(.61,.08,.065,.01),(.67,.085,.06,.01)],coat)
for i in range(12):
 a=i*math.tau/12
 rod('Gathered fold',(.16*math.cos(a),.5,.13*math.sin(a)),(.075*math.cos(a),.64,.06*math.sin(a)),.008,pants)
ring('Tie',(0,.62,0),.08,.012,leather,axis='y')
export('coal_sack')
