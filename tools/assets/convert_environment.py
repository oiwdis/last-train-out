"""Extract a reusable CC0 architectural kit, bench and weeds from Poly Haven sources.

Blender 4.3.2; source downloads/checksums are in assets/environment/sources.json.
The kit retains the source UVs, normals and PBR maps. No gameplay collision is exported.
"""
import json
import os
import struct
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(os.environ.get("LTO_ENV_SOURCE", "/tmp/lto27-sources"))
OUT = ROOT / "assets/environment"
OUT.mkdir(parents=True, exist_ok=True)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def export(name, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUT / (name + ".glb")), export_format="GLB",
        use_selection=True, export_animations=False, export_cameras=False,
        export_lights=False, export_image_format="JPEG", export_jpeg_quality=90,
    )
    # Keep Godot's adjacent extracted images reproducible, including duplicate
    # image names with different alpha encodings. This also repairs a clean
    # checkout with a restored import cache whose extracted sources are absent.
    payload = (OUT / (name + ".glb")).read_bytes()
    length = struct.unpack_from("<I", payload, 12)[0]
    document = json.loads(payload[20:20+length])
    binary = payload[28+length:]
    used = set()
    for index, image in enumerate(document.get("images", [])):
        image_name = image["name"]
        if image_name in used:
            image_name += "_" + str(index)
        used.add(image["name"])
        extension = ".png" if image["mimeType"] == "image/png" else ".jpg"
        view = document["bufferViews"][image["bufferView"]]
        data = binary[view.get("byteOffset", 0):][:view["byteLength"]]
        (OUT / (name + "_" + image_name + extension)).write_bytes(data)


clear()
bpy.ops.import_scene.gltf(filepath=str(next((SOURCE / "modular_factory_facade").glob("*.gltf"))))
originals = {obj.name: obj for obj in bpy.context.scene.objects if obj.type == "MESH"}
modules = []


def module(name, sources, offset=(1.5, 0, 0), broken=False):
    copies = []
    bpy.ops.object.select_all(action="DESELECT")
    for source in sources:
        obj = originals[source].copy()
        obj.data = obj.data.copy()
        bpy.context.collection.objects.link(obj)
        obj.matrix_world = Matrix.Identity(4)
        obj.data.transform(Matrix.Translation(offset))
        obj.select_set(True)
        copies.append(obj)
    bpy.context.view_layer.objects.active = copies[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    if broken:
        # Remove discrete panes, retaining the source steel frame. Small shards
        # remain in the lower edges; this is modeled damage, not a dark decal.
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        faces = []
        for face in mesh.faces:
            mat = obj.data.materials[face.material_index]
            center = face.calc_center_median()
            if "glass" in mat.name and (center.x < -0.35 or center.z > 0.25):
                faces.append(face)
        bmesh.ops.delete(mesh, geom=faces, context="FACES")
        mesh.to_mesh(obj.data)
        mesh.free()
    modules.append(obj)
    return obj


module("FacadeWindow", ["wall_window_centered_large_01", "window_centered_large_01"])
module("FacadeSolid", ["wall_standard_standard_01"])
module("LoadingBay", ["wall_door_garage_door_01", "door_garage_door_01"], (3, 0, 0))
module("Cornice", ["cornice01_standard_standard_01"])
module("Plinth", ["base_standard_standard_01"])
module("Window", ["window_centered_large_01"], (1.5, 0, -1.462653))
module("BrokenWindow", ["window_centered_large_01"], (1.5, 0, -1.462653), broken=True)
for material in bpy.data.materials:
    if "windows_glass" in material.name:
        shader = material.node_tree.nodes.get("Principled BSDF")
        if shader:
            shader.inputs["Roughness"].default_value = 0.3
for obj in modules:
    # Split by material to preserve every surface during CutawayWall fades.
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="MATERIAL")
    bpy.ops.object.mode_set(mode="OBJECT")
    pieces = list(bpy.context.selected_objects)
    parent = bpy.data.objects.new(obj.name + "_Root", None)
    bpy.context.collection.objects.link(parent)
    for piece in pieces:
        piece.parent = parent
export("factory_kit", [o for o in bpy.context.scene.objects if o.name not in originals])

for asset, budget in [("painted_wooden_bench", 7000), ("weed_plant_02", 1200)]:
    clear()
    bpy.ops.import_scene.gltf(filepath=str(next((SOURCE / asset).glob("*.gltf"))))
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    # Use the first complete plant variant; avoid importing an entire layout.
    if asset == "weed_plant_02":
        objects = [min(objects, key=lambda obj: obj.name)]
    points = [o.matrix_world @ Vector(v) for o in objects for v in o.bound_box]
    low = Vector([min(v[i] for v in points) for i in range(3)])
    high = Vector([max(v[i] for v in points) for i in range(3)])
    offset = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        matrix = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = matrix
        obj.location -= offset
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = asset
    triangles = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if triangles > budget:
        modifier = obj.modifiers.new("Game mesh budget", "DECIMATE")
        modifier.ratio = budget / triangles
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    print("ENV_ASSET", asset, "dimensions", list(high - low), flush=True)
    export(asset, [obj])
