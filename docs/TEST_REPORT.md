# Test report — Milestone 2.5

## Baseline and automated coverage

Milestone 2 commit `444fafc250527058021fce4516e6ef816b0a1a0f` passed **147/147** tests
before implementation with official **Godot 4.5.1-stable**, Linux x86_64, Jolt and 60 Hz physics.
Milestone 2.5 passes **168/168** locally: all 147 previous cases remain, plus 21 new cases.
Project import and the 600-frame main-scene smoke also pass without engine/script errors.
The final full suite took **74.8 seconds** while screenshot rendering also ran on the shared
CPU; suite wall time is not game FPS. CI requires at least 168 passing tests.

| New suite | Tests | Coverage |
|---|---:|---|
| Exploration camera | 12 | FP/TP initialization, physical V, mouse bounds, camera-relative input at four yaws, swept collision, state/cargo preservation, queued vault switching, departure riding, searches in both views, range/occlusion, held-cargo storage targeting, settings and independent menus |
| Train interiors | 5 | Walking/braking inside a moving crew car, crossing all three cars, look-targeted cab controls and all modes, closed-door collision/occupied-door safety, interior jump/switch/reset |
| Exploration district | 4 | Exterior routes, waiting-hall/platform approach, container ladder/roof, reset of doors and camera state |

Perspective-dependent assertions now test opaque immersive walls and a player-controlled
camera. Separate component tests retain the old cutaway fade/collision behavior for the
movement sandbox. Route bots aim at interactions; freight traversal brakes explicitly
where the removed invisible lane wall previously stopped the player. Movement, jump timing,
stamina, boarding, moving ladders, inheritance, interpolation, inventory and conservation
coverage remains. Existing rendered rider/climber tests still report 0.00000 m relative drift.

[Full local run](validation/milestone25-linux-tests.log) and
[headless app self-test report](validation/milestone25-linux-selftest.json) are retained.
The latter loads the source project, so `exported_build` is correctly false. It verifies
both perspectives, a moving interior walk, cab operation, searches, transfers, cargo anchors,
all presets and UI without engine errors. A final cosmetic change makes supply labels face
the camera, and the export excludes documentation media; macOS CI checks the resulting commit.

## Reproduction

```bash
MIN_TESTS=168 tools/run_tests.sh /path/to/Godot_v4.5.1-stable
/path/to/Godot_v4.5.1-stable --headless --path . --fixed-fps 60 \
  scenes/main/self_test.tscn -- --selftest-report=/tmp/selftest.json
```

Local logs are in `tests/_output/`. Sandboxed Linux runs use writable XDG data/config/cache
directories. The test wrapper checks stderr and shutdown errors as well as assertions.
Headless runs omit audio playback; graphical builds retain spatial engine, steps and latches.

## Rendered evidence

[The screenshots](screenshots/milestone25/) cover the platform in both views, train exterior,
crew interior, cab, Warehouse A, Warehouse B, freight yard, waiting hall and camera/inventory
settings. Additional tour frames show moving-train riding, a search, cargo in both views and
the final train hold. These are actual game renders without painting or compositing.

The [gameplay recording](recording/milestone25_tour.mp4) uses Godot Movie Maker and explicit
location cuts. It presses V and E, starts the locomotive from the cab, walks in the moving
crew car, searches two caches, picks up the discovered coal sack, changes perspective while
holding it, walks at the heavy-carry speed, drops/recovers it and deposits it. Assertions verify
that the same sack is held, recovery works, the storage target remains usable while carrying,
and exactly one discovered sack reaches storage. This is scripted evidence, not a human playtest.

```bash
godot --path . --audio-driver Dummy --fixed-fps 60 tools/capture_milestone25.tscn
godot --path . --audio-driver Dummy --fixed-fps 24 \
  --write-movie /tmp/milestone25.avi tools/record_milestone25.tscn
```

Captures use Linux Xvfb and Mesa software graphics. Still views use High; the tour uses Medium.
Movie Maker's output rate is not a performance measurement. The separate
[performance report](PERFORMANCE.md) contains matched real-time samples and hardware limits.

## macOS export and delivery

The existing universal export, ad-hoc signing, bundle/ZIP checks and fresh-download launch
jobs remain. The verifier now includes imported JPG, GLB and WAV assets. Documentation media
is excluded from the app pack. Pull requests targeting the complete Milestone 2 branch run
this pipeline before merging. Developer ID signing/notarization remains optional and manual.

The final CI run and download are recorded here after verification.

## Remaining limits

- Art is visibly procedural, with repeated modules, simplified human faces/hands, sparse
  dressing and procedural limb animation. It does **not** meet the requested photorealistic
  quality bar. Cab gauge needles are static beside the live numerical speed display; the
  coal compartment is scenery, not a new fuel-consumption simulation.
- The user's **2020 M1, full-screen** configuration was not available for a human playtest or
  physical performance measurement. Its display resolution and macOS version are unspecified.
  The expanded scene is slower than M2 on the software renderer; Low's measured shading
  improvement is not proof of playable M1 performance. No 60 FPS result is claimed.
- Linux graphics are software-rendered. GitHub Apple Silicon uses a virtual GPU; Intel CI
  runs headlessly and does not verify Intel windowed rendering. Unsupported volumetric fog
  remains guarded. No manual control-feel or listening test is claimed.
- Development apps are ad-hoc signed, not notarized. Follow the README's first-launch steps.
  GitHub downloads require sign-in and expire after 30 days.
- Camera and graphics preferences persist; inventory/train progress resets on relaunch.
  Heavy cargo collides with world/train geometry, but does not block players or other cargo.
- Dangerous advancing fog, combat, damage, crafting, consumption, passengers, train upgrades,
  additional stations and full save/load remain future work. Audio is synthesized, not field-recorded.

Historical reports: [Milestone 2](MILESTONE_2_TEST_REPORT.md),
[Milestone 1.5](MILESTONE_1_5_TEST_REPORT.md), [Milestone 1](MILESTONE_1_TEST_REPORT.md).
