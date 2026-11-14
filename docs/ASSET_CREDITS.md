# Asset credits and licenses

No purchased, ripped or game-extracted assets are included. The game has no third-party
runtime plugin dependency. Original project artwork and source are distinguished below
from third-party CC0 models, animations and material maps; this document does not change the project's overall license.

## Poly Haven textures

All downloaded maps are provided under [CC0 1.0](https://polyhaven.com/license), permitting
commercial use, redistribution and modification without attribution requirements. Attribution
is retained here. Maps are unmodified 1K JPG albedo, OpenGL normal and roughness; Godot creates
compressed, mipmapped runtime imports. No displacement maps are shipped.

| Asset and source | Credited authors | License |
|---|---|---|
| [brick_wall_001](https://polyhaven.com/a/brick_wall_001) | Rob Tuytel, Dimitrios Savva | CC0 1.0 |
| [rusty_painted_metal](https://polyhaven.com/a/rusty_painted_metal) | Amal Kumar | CC0 1.0 |
| [wood_planks_grey](https://polyhaven.com/a/wood_planks_grey) | Rob Tuytel | CC0 1.0 |
| [concrete_floor_worn_001](https://polyhaven.com/a/concrete_floor_worn_001) | Dimitrios Savva, Rico Cilliers | CC0 1.0 |
| [asphalt_02](https://polyhaven.com/a/asphalt_02) | Rob Tuytel | CC0 1.0 |
| [denim_fabric](https://polyhaven.com/a/denim_fabric) | Rob Tuytel | CC0 1.0 |
| [rusty_corrugated_iron](https://polyhaven.com/a/rusty_corrugated_iron) | Charlotte Baglioni | CC0 1.0 |
| [gravel_stones](https://polyhaven.com/a/gravel_stones) | Amal Kumar | CC0 1.0 |
| [green_metal_rust](https://polyhaven.com/a/green_metal_rust) | Rob Tuytel | CC0 1.0 |

`assets/pbr/sources.json` records every original download URL, local path and SHA-256 checksum.
`tools/fetch_pbr.py` reproduces the downloads using the public Poly Haven API and curl.
The rusty painted metal set remains available as a shared source even where the final train
uses green weathered metal. Milestone 2.6 adds scanned gravel for ballast and a licensed photographic sky, listed below. The coal sack uses a tinted denim fabric scan; its tied geometry remains original project work.

## Milestone 2.6 character

| Asset | Creator and primary source | License | Modifications and usage |
|---|---|---|---|
| MakeHuman base human, Mixamo-style 52-bone rig and weights | [MakeHuman Community / MPFB](https://github.com/makehumancommunity/mpfb2), pinned commit `9de0707fdc88438d7c53a1a2ac7937d9221e2431` | [CC0 assets](https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md) | Adult male phenotype; baked morphs, hidden skin removed, facial subdivision, rest-pose alignment, glTF export. Third-person character and dedicated first-person skin geometry. |
| `male_casualsuit05`, `short02`, `eyebrow004`, low-poly eyes with brown iris | [MakeHuman system assets](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html); MakeHuman Community, Data Collection AB, Joel Palmius, Jonas Hauquier | CC0, explicit September 2020 asset release | Fitted jacket, shirt, denim trousers; cropped hair, brows and eye geometry. Iris subdivision, standard PBR conversion. First-person sleeves use the same authored mesh, UVs and material. |
| Aksel skin | [Mindfront, Skins02 pack](https://static.makehumancommunity.org/assets/assetpacks/skins02.html) | CC0 | Authored diffuse and normal maps resized to 2K; subdued normal intensity. Face, neck, hands and first-person arms. |
| Ankle boots, male | [Margaret Toigo (MRT), Shoes01 pack](https://static.makehumancommunity.org/assets/assetpacks/shoes01.html) | CC0, also declared in the `.mhclo` header | Fitted authored leather boots and normal map; skinning transferred to the worker rig. |
| Universal Animation Library, free Standard edition | [Quaternius](https://quaternius.itch.io/universal-animation-library); animation collaboration credited on the source page to Gonzalo Furnier | CC0 1.0, shipped `License.txt` | Walking, sprinting, jumping, landing, pickup and interaction clips retargeted to the MakeHuman anatomy. Root motion removed. Source mannequin is **not** included. |

MPFB is a GPL-3.0 development tool; its license explicitly distinguishes CC0 asset data and generated models from program code. MPFB and Blender are not runtime dependencies and are not distributed in the game. `assets/characters/sources.json` records the source commit and archive checksums. The original neutral breathing, carry, carry-walk, climb, hang, vault, drop and five dedicated first-person action adaptations are authored in `tools/assets/retarget_worker.py` on the weighted skeleton.

## Milestone 2.6 locomotive and sky

| Asset | Creator and primary source | License | Modifications and usage |
|---|---|---|---|
| Steam Locomotive | [Roland Schuller / BlenderKit](https://www.blenderkit.com/asset-gallery-detail/469880dd-585b-4a9d-955e-b8b593421adf/) | CC0 (`cc_zero` in the public asset API), free asset | Original exterior topology, boiler, pipework, wheel assemblies, suspension, panels and couplings. Scaled to the game, rear cab adapted for the existing gangway, static parts consolidated, mesh budgets applied, UVs remapped at metre scale and source Cycles finishes replaced with the credited Poly Haven PBR maps. The existing train integrator is unchanged. |
| Kloofendal Overcast (Pure Sky) | [Greg Zaal / Poly Haven](https://polyhaven.com/a/kloofendal_overcast_puresky) | CC0 | 1K HDR panorama; reduced exposure for overcast station lighting and reflections. Download and checksum in `assets/sky/source.json`. |

`assets/train/*_finish.glb` and `carriage_door.glb` and `control_lever.glb` are original fitted carriage/cab finishing meshes: window seals, glazing, panel seams, rivets, roof construction, interior timber, pipework, gauges, handrails and hinged door hardware. Generated by `tools/assets/build_carriages.py`, using the credited Poly Haven materials. Their dimensions follow the existing walkable floors and door openings.

## Milestone 2.6 industrial models

All models below are CC0 under [Poly Haven’s asset license](https://polyhaven.com/license). Original authored geometry, UVs and albedo/normal/roughness/metallic/AO data are retained where supplied. Changes: 1K textures, selected variants, grounded pivots, consolidation by material and mesh reduction for small props. Repeated static objects are spatially batched with MultiMesh; Godot generates runtime LODs and compressed mipmaps. Source URLs, authors and original file SHA-256 values are recorded in `assets/props/sources.json`; processed mesh counts are in `mesh_metrics.json`.

| Asset | Creator | Usage |
|---|---|---|
| [Drill Press 01](https://polyhaven.com/a/drill_press_01) | Viktor | Warehouse A and B work surfaces |
| [Industrial Storage Cart](https://polyhaven.com/a/industrial_storage_cart) | Jule Bielitz | Warehouses and freight-yard maintenance areas |
| [Worn Metal Rack](https://polyhaven.com/a/worn_metal_rack) | Luca B | Replacement warehouse shelving in both halls |
| [Wooden Military Crate](https://polyhaven.com/a/wooden_military_crate) | Prabhjinder Singh | Freight-yard cargo |
| [Vintage Suitcase](https://polyhaven.com/a/vintage_suitcase) | Maximilian Schuster | Platform luggage and crew-car interior |
| [Hand Truck](https://polyhaven.com/a/hand_truck) | Mutanzom3D | Platform, warehouse loading areas and freight yard |
| [Industrial Caged Sconce](https://polyhaven.com/a/industrial_caged_sconce) | Ulan Cabanilla | Warehouse walls, locomotive cab and crew interior |
| [Brass Blowtorch](https://polyhaven.com/a/brass_blowtorch) | Ulan Cabanilla | Warehouse A workbench |
| [Small Oil Can 01](https://polyhaven.com/a/small_oil_can_01) | Raven van de Werken | Warehouse workbenches and locomotive cab |
| [Steel Frame Shelves 02](https://polyhaven.com/a/steel_frame_shelves_02) | James Ray Cock | Tall warehouse shelf replacement |
| [Barrel 02](https://polyhaven.com/a/Barrel_02) | Jorge Camacho | Warehouse exit and freight-yard maintenance area |
| [Wooden Crate 01](https://polyhaven.com/a/wooden_crate_01) | James Ray Cock | Replacement solid crate stacks throughout the station |
| [Caged Hanging Light](https://polyhaven.com/a/caged_hanging_light) | Ulan Cabanilla | Warehouse ceiling fixtures |
| [Vintage Flashlight](https://polyhaven.com/a/vintage_flashlight) | Omar M. El-Safy | Worker utility belt; skeleton-mounted with original belt geometry |

## Original work for this repository

- Legacy Milestone 2.5 `assets/models/*.glb`: procedural worker and steam machinery (retired from active use),
  spoked wheels, beveled fabrication mesh and tied coal sack. Created from original geometry
  in `tools/build_original_models.py`; no third-party model, rig or animation is embedded.
- Train interiors, station hall, warehouses, fittings, signs, ladders, containers and props:
  authored scenes and GDScript geometry in `scripts/environment` and `scripts/presentation`.
- `assets/audio/*.wav`: deterministic synthesized wind, engine rhythm, footfall and latch,
  generated by `tools/build_original_audio.py`. No samples or external recordings are used.
- Inventory SVG icons and railway UI: original project artwork. Text uses Godot's built-in
  fallback font; no additional font file is redistributed by this project.

Regenerate models with Blender 4.3.2 or compatible: `blender -b --python tools/build_original_models.py`.
Regenerate audio with Python 3: `python3 tools/build_original_audio.py`. These are development
commands; players only need the packaged app. Blender itself is not distributed in the app.

Godot 4.5.1 and its bundled engine components retain the licenses included in the official
export template. Their engine license information is available at <https://godotengine.org/license/>.

Reproduction commands, source verification and import-integrity checks: [ASSET_PIPELINE.md](ASSET_PIPELINE.md).
