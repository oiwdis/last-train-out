"""Original manufactured railway meshes, built in Blender 4.3.2, in Godot metres.

Folded sheets, rolled roof sections, wheel profiles, leaf springs and door gear
replace the blockout silhouettes. Scanned CC0 PBR maps retain metre-scale UVs.
Collision remains solely in the gameplay scenes.
"""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/environment"
OUT.mkdir(exist_ok=True)
METRICS = []


def xyz(value):
    return Vector((value[0], -value[2], value[1]))


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, color, metal=0, texture=None, roughness=0.7):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metal
    shader.inputs["Roughness"].default_value = roughness
    if texture:
        for kind, socket in [("albedo", "Base Color"), ("roughness", "Roughness"), ("normal", None)]:
            image = nodes.new("ShaderNodeTexImage")
            image.image = bpy.data.images.load(str(ROOT / "assets/pbr" / f"{texture}_{kind}.jpg"), check_existing=True)
            if kind != "albedo":
                image.image.colorspace_settings.name = "Non-Color"
            if socket:
                links.new(image.outputs["Color"], shader.inputs[socket])
            else:
                normal = nodes.new("ShaderNodeNormalMap")
                normal.inputs["Strength"].default_value = 0.45
                links.new(image.outputs["Color"], normal.inputs["Color"])
                links.new(normal.outputs["Normal"], shader.inputs["Normal"])
    return mat


clear()
paint = material("Weathered red oxide steel", (.33, .13, .08), .4, "rusty_painted_metal")
steel = material("Oiled forged steel", (.035, .045, .047), .75, roughness=.46)
edge = material("Exposed galvanized edges", (.32, .35, .34), .8, roughness=.42)
wood = material("Seasoned freight timber", (.24, .2, .14), 0, "wood_planks_grey")
roof_mat = material("Corroded roofing sheets", (.19, .2, .18), .55, "rusty_corrugated_iron")
rubber = material("Door seal rubber", (.018, .021, .022), roughness=.86)
enamel = material("Aged freight stencils", (.61, .59, .49), roughness=.86)
concrete = material("Weathered concrete coping", (.42, .43, .4), 0, "concrete_floor_worn_001")
brick = material("Station gable brickwork", (.45, .3, .23), 0, "brick_wall_001")


def mesh(name, vertices, faces, mat, smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata([xyz(p) for p in vertices], [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(mat)
    for face in data.polygons:
        face.use_smooth = smooth
    return obj


def box(name, at, size, mat, bevel=.006):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(at))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Machined edge radius", "BEVEL")
        mod.width, mod.segments = bevel, 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def tube(name, points, radius, mat, resolution=1):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth, curve.bevel_resolution = radius, resolution
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, at in zip(spline.points, points):
        point.co = (*xyz(at), 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def beam(name, start, end, width, depth, mat):
    a, b = xyz(start), xyz(end)
    obj = box(name, (0, 0, 0), (width, (b-a).length, depth), mat, .003)
    obj.location = (a+b) / 2
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = (b-a).to_track_quat("Z", "Y")
    return obj


def lathe(name, at, profile, mat, axis="z", segments=32):
    # Profile is (distance along axle, radius); retain the flange, dish and hub.
    vertices, faces = [], []
    for depth, radius in profile:
        for i in range(segments):
            angle = i * math.tau / segments
            p = (math.cos(angle)*radius, math.sin(angle)*radius, depth)
            if axis == "x":
                p = (depth, p[0], p[1])
            vertices.append(tuple(at[j]+p[j] for j in range(3)))
    for ring in range(len(profile)-1):
        for i in range(segments):
            j = (i+1) % segments
            faces.append((ring*segments+i, ring*segments+j, (ring+1)*segments+j, (ring+1)*segments+i))
    return mesh(name, vertices, faces, mat, True)


def bolt(at, axis="z", radius=.018):
    return lathe("Hexagonal bolt", at, [(0, 0), (0, radius), (.012, radius), (.012, 0)], edge, axis, 6)


def corrugated(name, center, length, height, mat, side=1, axis="x", pitch=.26, amplitude=.035):
    count = max(1, round(length / pitch))
    vertices, faces = [], []
    for i in range(count+1):
        for t, depth in [(0, 0), (.18, 0), (.32, amplitude), (.68, amplitude), (.82, 0)]:
            if i == count and t > 0:
                continue
            u = -length/2 + (i+t)*length/count
            for y in [-height/2, height/2]:
                p = (u, y, side*depth) if axis == "x" else (side*depth, y, u)
                vertices.append(tuple(center[j]+p[j] for j in range(3)))
    for i in range(len(vertices)//2-1):
        faces.append((i*2, i*2+1, i*2+3, i*2+2))
    obj = mesh(name, vertices, faces, mat)
    # The thin closed skin shades correctly from both sides without alpha blending.
    mod = obj.modifiers.new("Folded sheet thickness", "SOLIDIFY")
    mod.thickness = .004
    return obj


def stencil(text, at, size, yaw=0):
    curve = bpy.data.curves.new("Freight identification", "FONT")
    curve.body = text
    curve.size, curve.extrude = size, 0
    curve.align_x = "CENTER"
    obj = bpy.data.objects.new("Stencilled identification", curve)
    bpy.context.collection.objects.link(obj)
    obj.location = xyz(at)
    obj.rotation_euler = (math.pi/2, 0, yaw)
    obj.data.materials.append(enamel)
    return obj


def export(name):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for obj in bpy.context.selected_objects:
        uv = obj.data.uv_layers.new(name="MetreUV")
        for face in obj.data.polygons:
            axis = max(range(3), key=lambda i: abs(face.normal[i]))
            a, b = [i for i in range(3) if i != axis]
            for index in face.loop_indices:
                vertex = obj.data.vertices[obj.data.loops[index].vertex_index].co
                uv.data[index].uv = (vertex[a], vertex[b])
        for old in list(obj.data.uv_layers):
            if old != uv:
                obj.data.uv_layers.remove(old)
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    triangles = sum(len(face.vertices)-2 for face in obj.data.polygons)
    METRICS.append({"name": name, "triangles": triangles, "dimensions_blender": list(obj.dimensions)})
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+".glb")), export_format="GLB", use_selection=True, export_animations=False, export_image_format="NONE")
    clear()


# 20-foot container, fitted to the existing 6 x 2.7 x 2.5 metre traversal volume.
for side in [-1, 1]:
    corrugated("Pressed side panels", (0, 1.36, side*1.205), 5.76, 2.4, paint, side)
    for y in [.08, 2.62]:
        box("Welded longitudinal rail", (0, y, side*1.21), (5.82, .14, .08), paint)
    for end in [-1, 1]:
        box("Corner post", (end*2.91, 1.35, side*1.205), (.16, 2.46, .09), paint)
        for y in [.09, 2.61]:
            # Open rectangular casting with a real lifting pocket.
            for dx in [-.065, .065]:
                box("Corner casting jamb", (end*2.91+dx, y, side*1.23), (.045, .17, .06), edge, .012)
            for dy in [-.062, .062]:
                box("Corner casting lip", (end*2.91, y+dy, side*1.23), (.16, .045, .06), edge, .012)
    stencil("H J   /   R A I L   F R E I G H T", (0, 1.75, side*1.248), .16, 0 if side>0 else math.pi)
    for x in [-1.2, 1.2]:
        box("Forklift pocket shadow", (x, .12, side*1.254), (.38, .11, .008), steel, .008)
box("Container roof", (0, 2.68, 0), (5.8, .035, 2.36), paint)
for i in range(23):
    box("Pressed roof stiffener", (-2.75+i*.25, 2.698, 0), (.09, .012, 2.27), paint, .005)
for end in [-1, 1]:
    for y in [.08, 2.62]:
        box("End frame", (end*2.94, y, 0), (.1, .14, 2.47), paint)
    if end < 0:
        corrugated("Rear bulkhead", (-2.94, 1.35, 0), 2.31, 2.4, paint, -1, "z")
        continue
    for side in [-1, 1]:
        z = side*.585
        box("Door leaf gasket", (2.944, 1.35, z), (.025, 2.39, 1.15), rubber, .018)
        corrugated("Pressed door leaf", (2.963, 1.35, z), 1.08, 2.3, paint, 1, "z", .23, .018)
        for dz in [-.33, .33]:
            tube("Locking bar", [(2.994,.19,z+dz),(2.994,2.51,z+dz)], .016, edge)
            for y in [.3, 1.25, 2.4]:
                box("Locking-bar keeper", (3.0,y,z+dz), (.025,.07,.09), edge, .004)
            tube("Locking handle", [(3.0,1.15,z+dz),(3.025,1.1,z+dz),(3.025,1.1,z+dz+.2)], .012, steel)
        for y in [.48, 1.36, 2.22]:
            tube("Door hinge", [(2.986,y-.055,side*1.13),(2.986,y+.055,side*1.13)], .025, edge)
    stencil("HLJU 073614 2", (3.035,2.12,.43), .105, math.pi/2)
export("freight_container")

# Closed timber box van with full flanged wheelsets, suspension and brake gear.
for side in [-1, 1]:
    z = side*1.285
    for i in range(15):
        box("Weathered tongue-and-groove siding", (0,1.08+i*.173,z), (6.74,.165,.04), wood, .004)
    for x in [-3.32,-2.0,-1.15,1.15,2.0,3.32]:
        box("Steel side stanchion", (x,2.35,z+side*.032), (.075,2.65,.055), paint)
        for y in [1.17,1.65,2.32,3.0,3.56]:
            bolt((x,y,z+side*.064))
    for end in [-1,1]:
        beam("Diagonal tension strap", (end*1.3,1.12,z+side*.04),(end*3.2,3.55,z+side*.04),.055,.022,paint)
    for i in range(13):
        box("Sliding door planks", (-1.08+i*.18,2.25,z+side*.09), (.172,2.37,.045),wood,.004)
    for y in [1.12,2.25,3.39]:
        box("Door steel cross band", (0,y,z+side*.123),(2.38,.07,.025),paint)
    box("Door top running rail", (0,3.57,z+side*.13),(4.9,.07,.09),steel)
    box("Door lower guide", (0,1.04,z+side*.12),(4.9,.045,.055),steel)
    for x in [-.9,.9]:
        lathe("Door roller",(x,3.52,z+side*.13),[(0,0),(0,.07),(.025,.07),(.025,0)],edge)
        box("Roller bracket",(x,3.4,z+side*.12),(.06,.27,.025),paint)
    tube("Door pull",[(.85,2.0,z+side*.15),(.85,2.0,z+side*.22),(.85,2.3,z+side*.22),(.85,2.3,z+side*.15)],.016,steel)
    stencil("H J   0 8 4   /   1 2 T",(-2.3,2.52,z+side*.07),.13,0 if side>0 else math.pi)
    box("Underframe channel web",(0,.83,side*1.12),(7.0,.22,.035),steel)
    for y in [.72,.94]:
        box("Underframe channel flange",(0,y,side*1.12),(7,.035,.16),steel)
for end in [-1,1]:
    for i in range(15):
        box("End wall planks",(end*3.38,1.08+i*.173,0),(.05,.165,2.54),wood,.004)
    box("Buffer beam",(end*3.43,.85,0),(.16,.28,2.52),paint)
    for z in [-.82,.82]:
        lathe("Sprung buffer",(end*3.5,.91,z),[(0,.07),(end*.21,.07),(end*.22,.18),(end*.25,.18)],steel,"x",24)
    tube("Coupling drawhook",[(end*3.52,.82,0),(end*3.72,.82,0),(end*3.78,.72,0),(end*3.7,.68,0)],.038,steel)
    for y in [1.1,3.5]:
        box("End cross member",(end*3.42,y,0),(.06,.09,2.62),paint)
vertices, faces = [], []
for x in [-3.49,3.49]:
    for i in range(33):
        z=-1.36+i*2.72/32
        vertices.append((x,3.7+.1*(1-(z/1.36)**2),z))
for i in range(32):
    faces.append((i,i+1,34+i,33+i))
mesh("Rolled arched box-van roof",vertices,faces,roof_mat,True)
for x in [-3.4,-2.25,-1.1,0,1.1,2.25,3.4]:
    tube("Raised roof seam",[(x,3.705+.1*(1-((-1.36+i*2.72/16)/1.36)**2),-1.36+i*2.72/16) for i in range(17)],.012,edge)
for x in [-2.6,-1.6,1.6,2.6]:
    tube("Wheelset axle",[(x,.52,-1.1),(x,.52,1.1)],.06,steel)
    for side in [-1,1]:
        z=side*.88
        profile=[(-.11,.09),(-.11,.39),(-.08,.425),(-.045,.425),(-.035,.385),(.06,.385),(.07,.31),(.025,.24),(.07,.11),(.09,.09)]
        lathe("Forged flange and dished wheel",(x,.52,z),profile,steel)
        lathe("Axle hub cap",(x,.52,side*1.035),[(0,0),(0,.115),(.065,.115),(.07,.09),(.07,0)],edge)
        box("Axlebox",(x,.58,side*1.12),(.22,.2,.17),steel,.025)
        for leaf in range(4):
            length=.73-leaf*.1
            points=[(x-length/2+i*length/12,.72+leaf*.018+.055*(1-((i-6)/6)**2),side*1.12) for i in range(13)]
            vertices, faces = [], []
            for p in points:
                for dy,dz in [(-.006,-.0375),(-.006,.0375),(.006,.0375),(.006,-.0375)]:
                    vertices.append((p[0],p[1]+dy,p[2]+dz))
            for segment in range(12):
                for corner in range(4):
                    next_corner=(corner+1)%4
                    faces.append((segment*4+corner,segment*4+next_corner,(segment+1)*4+next_corner,(segment+1)*4+corner))
            faces.extend([(3,2,1,0),(48,49,50,51)])
            mesh("Laminated leaf spring",vertices,faces,steel)
        for dx in [-.32,.32]:
            box("Spring hanger",(x+dx,.8,side*1.12),(.065,.24,.08),paint)
            bolt((x+dx,.7,side*1.17))
lathe("Air brake reservoir",(0,.53,0),[(-.7,0),(-.68,.12),(-.6,.16),(.6,.16),(.68,.12),(.7,0)],steel,"x")
tube("Brake main pipe",[(-3.4,.67,.5),(3.4,.67,.5)],.022,edge)
export("parked_box_van")

# Pitched, corrugated roof with open timber trusses, fascia and rolled gutters.
for name,length,depth,rise in [("waiting_hall_roof",23.2,10.2,1.12),("station_house_roof",17.4,6.2,1.6)]:
    count=round(length/.18)
    vertices,faces=[],[]
    for i in range(count*4+1):
        x=-length/2+length*i/(count*4)
        corrugation=.018*math.cos(i*math.pi/2)
        for z in [-depth/2,0,depth/2]:
            vertices.append((x,rise*(1-abs(z)/(depth/2))+corrugation,z))
    for i in range(count*4):
        for j in range(2):faces.append((i*3+j,i*3+j+1,(i+1)*3+j+1,(i+1)*3+j))
    roofing = mesh("Pressed roofing sheet profile",vertices,faces,roof_mat)
    solid = roofing.modifiers.new("Roof underside", "SOLIDIFY")
    solid.thickness = .035
    wall_length = 22 if name == "waiting_hall_roof" else 16
    wall_depth = 9 if name == "waiting_hall_roof" else 5
    for end in [-1,1]:
        x = end*wall_length/2
        y = rise*(1-wall_depth/depth)
        mesh("Closed brick gable",[(x,0,-wall_depth/2),(x,y,-wall_depth/2),(x,rise,0),(x,y,wall_depth/2),(x,0,wall_depth/2)],[(0,1,2,3,4)],brick)
    for x in [-length/2,length/2]:
        for side in [-1,1]:
            beam("Gable fascia",(x,0,side*depth/2),(x,rise,0),.14,.09,wood)
    for side in [-1,1]:
        # A U-section gutter, genuinely open at the top.
        vertices,faces=[],[]
        for x in [-length/2,length/2]:
            for i in range(9):
                angle=math.pi+i*math.pi/8
                vertices.append((x,.075*math.sin(angle)-.025,side*depth/2+.075*math.cos(angle)))
        for i in range(8):faces.append((i,i+1,10+i,9+i))
        mesh("Rolled rain gutter",vertices,faces,edge,True)
        tube("Eaves flashing",[(-length/2,.01,side*depth/2),(length/2,.01,side*depth/2)],.018,edge)
    for i in range(1,round(length/4)+1):
        x=-length/2+.6+i*(length-1.2)/(round(length/4)+1)
        beam("Truss tie",(x,-.07,-depth/2+.2),(x,-.07,depth/2-.2),.12,.16,wood)
        for side in [-1,1]:
            beam("Truss rafter",(x,-.03,side*(depth/2-.2)),(x,rise-.12,0),.12,.16,wood)
            beam("Truss diagonal",(x,-.02,side*depth*.25),(x,rise-.12,0),.07,.09,steel)
        beam("King post",(x,-.06,0),(x,rise-.1,0),.1,.1,wood)
    export(name)

# Broken pallet/splinter cluster, kept against closed walls outside walking lanes.
for i in range(6):
    obj=box("Split pallet board",(-.55+i*.2,.035+(i%2)*.015,0),(.16,.045,.82 if i!=2 else .46),wood,.004)
    obj.rotation_euler.z=(i-2)*.035
for x in [-.45,.45]:
    box("Pallet runner",(x,.09,0),(.12,.08,.75),wood)
for i in range(7):
    obj=box("Splintered timber",(.7+i*.11,.02,.3*math.sin(i)),(.27,.025,.045),wood,.002)
    obj.rotation_euler.z=i*.8
export("broken_pallet")

# Small supply lockers fit the original searchable volumes; all fixtures are visual.
for name,medical in [("supply_locker",False),("medical_cabinet",True)]:
    box("Folded cabinet carcass",(0,.585,0),(.71,1.11,.43),paint,.018)
    box("Door perimeter gasket",(0,.585,.218),(.66,1.04,.012),rubber,.014)
    box("Recessed hinged door",(0,.585,.23),(.63,1.015,.018),paint,.012)
    for y in [.22,.91]:
        tube("Barrel hinge",[(-.322,y-.05,.24),(-.322,y+.05,.24)],.014,edge)
    tube("Recessed pull",[(.22,.5,.249),(.22,.5,.277),(.22,.66,.277),(.22,.66,.249)],.012,edge)
    lathe("Key escutcheon",(.22,.45,.25),[(0,0),(0,.023),(.009,.023),(.009,0)],edge,segments=16)
    for x in [-.285,.285]:
        for z in [-.16,.16]:box("Pressed steel foot",(x,.035,z),(.065,.07,.065),steel,.005)
    if medical:
        box("Medical cross vertical",(0,.8,.246),(.075,.29,.003),enamel,.001)
        box("Medical cross horizontal",(0,.8,.248),(.29,.075,.003),enamel,.001)
    else:
        for y in [.23,.265,.3,.84,.875,.91]:
            box("Vent louvre shadow",(-.04,y,.243),(.35,.012,.003),steel,.002)
            box("Pressed louvre lip",(-.04,y+.008,.249),(.35,.012,.011),edge,.002)
    export(name)

box("Toolbox tray",(0,.24,0),(.7,.46,.43),paint,.025)
box("Rolled lid lip",(0,.475,0),(.72,.045,.45),edge,.012)
box("Domed toolbox lid",(0,.51,0),(.7,.065,.43),paint,.025)
tube("Carry handle",[(-.11,.54,0),(-.11,.58,0),(.11,.58,0),(.11,.54,0)],.018,steel)
for x in [-.23,.23]:
    box("Over-centre clasp",(x,.46,.229),(.065,.11,.02),edge,.008)
    bolt((x,.46,.245),radius=.009)
export("supply_toolbox")
(OUT/"original_mesh_metrics.json").write_text(json.dumps(METRICS,indent=2)+"\n")
