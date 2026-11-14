# Milestone 2.5 — exploring Harlow in 3D

Harlow is a cold railway yard with warm occupied train interiors and pockets of practical
lighting. The art now uses full-size geometry, beveled fabricated edges, original curved
steam machinery and wheels, an articulated 1.78 m worker, and scanned CC0 surface maps.
The result aims for grounded industrial detail. It remains procedural game art; it does
not achieve or claim AAA photorealism, scanned characters or motion-captured animation.

## Spaces and construction

The original train integrator, roof heights and climbing anchors remain. Hollow crew and
cab shells replace solid boxes. Sills, posts, lintels and transparent windows enclose actual
interiors. End doors open onto narrow gangways. The crew car has benches and luggage racks;
the cab has physical regulator, brake and departure selector, gauges, speed readout, pipes,
and a coal compartment. The compartment is scenery: fuel consumption belongs to a later milestone.

The station retains both warehouse traversal routes and all thirteen seeded supply sites.
The new waiting hall has benches, an abandoned ticket counter and evacuation notices.
A service walk, trackside walk and four crossings connect the yard; additional containers
provide roof routes. Background silhouettes sit beyond the walkable perimeter. The warehouses
stay opaque when entered or passed on the train, and can be viewed from every side.

## Assets and rendering

`tools/build_original_models.py` is the Blender source for the worker, machinery, wheels,
beveled unit mesh and coal sack. Blender is a development tool only: the exported game uses
committed GLB files and needs no Blender installation. The worker has separate hips, knees,
shoulders and elbows; idle, walking, sprinting, jumping, climbing, vaulting and carrying poses
are driven by gameplay state. There is no camera head bob or landing shake.

Eight CC0 Poly Haven material sets use unmodified 1K albedo, OpenGL normal and roughness maps.
Imports enable mipmaps and VRAM compression. Standard materials share these textures, with
triplanar mapping on authored geometry. Static fittings, including cylinders and rivets,
are combined by material. Collision uses simple authored shapes independent of mesh detail.
See [ASSET_CREDITS.md](ASSET_CREDITS.md) for provenance and reproduction commands.

The sky supplies a blue-gray overcast gradient and reflections. Indoor lamps remain warm.
Low/Medium use depth haze; High uses supported volumetrics and ambient occlusion. Local lights
fade at distance on Low/Medium, and small decorative meshes do not cast additional shadows.
Glass and the small smoke/mote pools are the principal transparent surfaces.

## Evidence and limits

[Current screenshots](screenshots/milestone25/) and [the scripted tour](recording/milestone25_tour.mp4)
show actual rendered gameplay. Location cuts in the tour are explicit. They are not a manual
playtest or a frame-rate measurement. [Performance measurements](PERFORMANCE.md) describe
hardware and sampling limits; the user's physical 2020 M1 was not available.

Remaining art limits include repeated modular surfaces, simplified faces/hands and procedural
animation, static gauge needles beside the live speed readout, and sparse room dressing.
The original audio is synthesized wind, rolling machinery, footfalls and latches; it is not
a recording of a real steam locomotive. [Earlier visual work](MILESTONE_1_5_VISUAL_DESIGN.md)
and its images remain archived.
