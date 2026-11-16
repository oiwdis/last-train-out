# Milestone 2.6 asset pipeline

The production assets are committed: Blender, MakeHuman and downloads are **not** needed to play or export. Godot 4.5.1 imports the GLBs, generates mesh LODs, compressed textures and mipmaps. Headless import does not perform the editor’s automatic 3D-texture detection: run `configure_imports.py` after the initial import to set VRAM compression, high-quality block compression, normal-map handling and mipmaps explicitly. Keep the adjacent extracted image files and `.import` settings under version control; `.godot` is disposable.

## Sources and reproducibility

See [ASSET_CREDITS.md](ASSET_CREDITS.md) for individual licenses, creators, modifications and locations. All acquired model/animation/material data is CC0. MPFB itself is a GPL development tool, not shipped runtime code. Source archive SHA-256 values and the MPFB commit are recorded in `assets/characters/sources.json`; the other asset directories contain their own source manifests.

Use Blender **4.3.2** and Python 3.10+ to reproduce this conversion:

```sh
mkdir -p /tmp/last-train-out-assets/sources
# Download the free Standard animation ZIP using the publisher's download button:
# https://quaternius.itch.io/universal-animation-library
# Save as /tmp/last-train-out-assets/sources/quaternius_universal_animations_standard.zip
python3 tools/assets/fetch_sources.py

git clone https://github.com/makehumancommunity/mpfb2 /tmp/last-train-out-assets/mpfb2
git -C /tmp/last-train-out-assets/mpfb2 checkout 9de0707fdc88438d7c53a1a2ac7937d9221e2431
bash tools/assets/rebuild.sh
/path/to/godot --headless --path . --import
python3 tools/assets/configure_imports.py
/path/to/godot --headless --path . --import
python3 tools/assets/check_assets.py
```

The fetcher verifies recorded SHA-256 values and stops if a publisher changes an archive. It uses the free BlenderKit public download endpoint for Roland Schuller's locomotive, without an account or purchase; temporary download links are not committed. The animation download is intentionally a publisher-mediated manual step because its free download URL is session-specific. Source archives remain outside the game repository. `LTO_ASSET_WORK` or the individual `LTO_SOURCE_DIR`, `LTO_BUILD_DIR`, `LTO_MPFB_SOURCE`, `LTO_MAKEHUMAN_DATA` variables can relocate the build.

The tested character workflow fits authored MakeHuman topology, skin, clothes and boots; retains the 52-bone rig and weights; removes covered skin; aligns the arms from A-pose to the source T-pose without rotating torso/feet into foreign anatomical axes; and retargets Quaternius global rotation deltas with rest offsets. Animation root transforms never move the gameplay body. Original breathing and two-bone carry/climb adaptations are baked at 24 Hz. Dedicated FP skin/sleeve meshes share the same rig, UVs and materials. Five camera-specific carry/action clips relocate disconnected arm roots below the eye; this does not move the third-person body or gameplay collision.

Do not move a linked intermediate `.blend` into another directory without remapping/packing its textures. Run `build_worker.py` at the final build location before `retarget_worker.py`. `check_assets.py` rejects missing embedded character images, external GLB dependencies, invalid bounds, missing normals/materials and missing skin data and explicit compressed/mipmapped 3D texture settings. The export builder uses `--python-exit-code 1`, so Blender Python failures stop the build.

`convert_props.py` selects assembled variants, grounds pivots, consolidates meshes and applies per-prop triangle budgets. `convert_locomotive.py` bakes the source's evaluated geometry, adapts its rear cab to the existing walk-through footprint, separates wheel pivots, consolidates static parts and replaces Cycles-only materials with scanned PBR maps. `build_carriages.py` produces original fitted cab/carriage finishing, door and control-lever meshes. Collision remains in the gameplay scenes.

## Validation and evidence

### Environment continuation

The additional CC0 architectural kit, bench and vegetation sources are pinned in
`assets/environment/sources.json`. Rebuild just this pass with:

```sh
python3 tools/assets/fetch_environment.py
blender -b -t 4 --python-exit-code 1 --python tools/assets/convert_environment.py
blender -b -t 4 --python-exit-code 1 --python tools/assets/build_railway_environment.py
/path/to/godot --headless --path . --import
python3 tools/assets/configure_imports.py
/path/to/godot --headless --path . --import
```

`LTO_ENV_SOURCE` relocates the downloaded sources (default `/tmp/lto27-sources`).
The converter also extracts the GLB image payloads to Godot's adjacent paths;
commit these images and their import settings. Do not delete extracted source
images while retaining their cached imported scenes. The original railway GLBs
omit embedded image copies: `EnvironmentArt` resolves their named materials to
shared existing PBR maps with the authored metre UVs. The GLB alone is therefore
not the complete shaded presentation; validate the real game scene.

Factory modules retain separate single-material source meshes and use wall-local
MultiMeshes, so their materials survive the wall fade while repeated bays share
draw calls. Source meshes generate Godot LODs.
Verge vegetation uses 20 m spatial batches, alpha scissor and a 35 m visibility
range. The parked van's source budget is below 40,000 triangles; its laminar
springs use swept strips instead of hundreds of bevelled blocks.

The continuation camera script is `tools/capture_environment.tscn`. It uses eight
fixed 1280×720 High views and moves the freight camera clear of Warehouse B's
trim. Copy the same script to the baseline checkout; do not compare the new
freight view to the old camera which intersected the wall. Use the same renderer
and preset for both captures; an OpenGL fallback is not a Forward+ comparison.

```sh
python3 tools/assets/check_assets.py
MIN_TESTS=187 tools/run_tests.sh /path/to/godot
/path/to/godot --path . --resolution 1280x720 tools/capture_milestone26.tscn
/path/to/godot --path . --resolution 1280x720 --script tools/benchmark_milestone25.gd -- --suite=presets --samples=24 --out=/tmp/performance.json
```

Capture uses the same feet/camera/target/FOV for baseline and result. `--only=first_person_hands` or `--only=running_gear` selects additional views. Performance sampling uses real frame intervals with VSync off, no fixed FPS and no Movie Maker. A recording is gameplay evidence, not a benchmark. Inspect the images and animation recording in addition to the automated checks: the validator cannot establish realism or detect every skinning artifact.

## Finalization

`build_worker.py` now selects the system-pack middle-aged skin, high-poly eyes,
short04 hair, eyebrow001 and eyelashes01. The eyes' alpha channel is essential:
the high-poly mesh has an outer shell whose transparent region reveals the iris.
Keep that alpha connection in the GLB. Runtime eyes use scissor transparency;
hair/brows/lashes also use MSAA coverage on High. Skin normals come from the
credited Mindfront middle-aged normal map. Covered skin is removed conservatively
at the collar/cuffs; both FP meshes remain weighted to the 52-bone rig.
Normalize bone weights before applying the extraction mask: MPFB's source
weights are not normalized. Thresholding those raw weights removed parts of
the wrists/palms and cuffs. The regression suite now checks that all 15,334
fully arm-weighted skin vertices survive extraction. Preserve the animated
hand/foot orientation while solving limb positions to prevent wrist/boot roll.

`retarget_worker.py` emits `assets/characters/locomotion_metrics.json`, measuring
rearward ankle motion during low foot-height stance samples. Runtime cadence uses
the resulting walk/sprint values, capped at the reviewed walking/carrying/sprint
cadences to avoid rapid shuffling at controller speeds; a lightweight `SkeletonModifier3D` corrects
contacts after animation and keeps foot points in the supporting body's local
space. Grip tests read its post-modification snapshots because Godot restores
the unmodified animation pose after skeleton evaluation. No animation moves the
player collider. Forward hip translation is discarded during retargeting.

`convert_locomotive.py` removes the named source rod/crank pieces from the static
body, keeps the source wheel pivots, and recognizes the source's small wheel
misnamed `ScrewHead.027`. `TrainMechanics` supplies constant-length coupling rods,
quartered crank motion, crossheads and speed/regulator/brake needles. Gauges do
not claim a boiler-pressure simulation. `build_carriages.py` omits the old baked
needles so they cannot overlap the live ones.

`FabricatedMesh` projects metre-scaled UVs once for flat bevelled surfaces, with
fresh tangents and shared materials. This removes triplanar sampling from those
walls/floors while preserving the same PBR maps and independent collision shapes.
The same geometry service supplies channel ladders, bolted columns and continuous
background roofs. Detail dressing never adds collision.

Final comparison: `tools/capture_finalization.tscn`, High, 960×540, Forward+.
Copy this script and its parent capture script to both reference checkouts.
The comparison fixture uses the final licensed HDR, ambient energy, depth haze
and SSAO in all revisions; copy the HDR and its import metadata into the M2.5
capture checkout as an additional fixture. Moon direction/energy and tonemapping
are identical in the source scenes. Each revision keeps its authored local
light fixtures. This isolates artwork changes; it is not M2.5's original night
lighting. Performance measurements use each revision's actual game presets.
Setup frames execute real physics with the viewport's 3D drawing disabled;
each saved view re-enables drawing. The walk/run, carry and moving-wheel shots
come from the gameplay controller. `tools/record_finalization.tscn` uses real
E/V inputs, with explicit labelled tour cuts between sites; it additionally
asserts gantry climbing. Record it with Movie Maker at a fixed capture rate;
that recording is not a performance measurement.

The shipped `scripts/diagnostics/render_benchmark.gd` is the same preset/entry-pan
diagnostic used by native CI. See [M1_BENCHMARK.md](M1_BENCHMARK.md) for the physical
fullscreen procedure and [MILESTONE3_INTEGRATION.md](MILESTONE3_INTEGRATION.md) for
stable interfaces and likely merge conflicts.

Never commit a texture `.import` containing `valid=false`. The asset validator
rejects that failed-import state. CI retains compressed texture caches but
rebuilds imported scenes, whose dependency UIDs can reference removed images
after a character replacement. Historical benchmark imports repair only failed
metadata for byte-identical image sources, with an explicit equality check.

Skin scattering remains an available quality field but is disabled in the shipped
presets. Its separate-specular pipeline is isolated by the native diagnostic;
ordinary skin keeps the authored diffuse/normal maps and roughness. The macOS
export enables Godot 4.5 shader baking to include intermediate Metal shader code.
