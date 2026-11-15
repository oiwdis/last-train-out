# Test report — Milestone 2.5

## Baseline and automated coverage

Milestone 2 commit `444fafc250527058021fce4516e6ef816b0a1a0f` passed **147/147** tests
before implementation with official **Godot 4.5.1-stable**, Linux x86_64, Jolt and 60 Hz physics.
Milestone 2.5 passes **168/168** locally: all 147 previous cases remain, plus 21 new cases.
Project import and the 600-frame main-scene smoke also pass without engine/script errors.
The final full suite took **48.8 seconds** while tour rendering also ran on the shared
CPU; suite wall time is not game FPS. CI requires at least 168 passing tests.

| New suite | Tests | Coverage |
|---|---:|---|
| Exploration camera | 12 | FP/TP initialization, physical V, mouse bounds, camera-relative input at four yaws, swept collision, state/cargo preservation, queued vault switching, departure riding, searches in both views, range/occlusion, held-cargo storage targeting, settings and independent menus |
| Train interiors | 5 | Walking/braking inside a moving crew car, crossing all three cars, look-targeted cab controls and all modes, reticle targeting of open/closed panels, collision/occupied-door safety, interior jump/switch/reset |
| Exploration district | 4 | Exterior routes, waiting-hall/platform approach, container ladder/roof, reset of doors (including interrupted animations) and camera state |

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
all presets and UI without engine errors. Supply labels face the camera, open-door targeting follows the visible panel, and reset
cancels pending door animations. Both door cases were reproduced before their fixes and
now have regression assertions. The full local suite includes these final fixes.

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
The encoded tour is **745 frames / 31.042 seconds**, 1280×720 H.264 at 24 FPS with AAC audio.
The entire encoded file decodes without errors; sampled frames show the stated actions.
The tour completed every assertion. Movie Maker emitted an ObjectDB cleanup warning on exit;
this offline-capture warning did not occur in the local headless suite or Compatibility smoke.
A separate Compatibility/Low platform capture completed with no engine errors; Mesa warned
that VSync control was unsupported. [Tour log](validation/milestone25-recording.log),
[Compatibility log](validation/milestone25-compatibility.log).
Movie Maker's output rate is not a performance measurement. The separate
[performance report](PERFORMANCE.md) contains matched real-time samples and hardware limits.

## macOS export and delivery

The existing universal export, ad-hoc signing, bundle/ZIP checks and fresh-download launch
jobs remain. The verifier now includes imported JPG, GLB and WAV assets. Documentation media
is excluded from the app pack. Pull requests targeting the complete Milestone 2 branch run
this pipeline before merging. Developer ID signing/notarization remains optional and manual.

[macOS run #10](https://github.com/oiwdis/last-train-out/actions/runs/43625984990)
verified implementation `a3c47b5` on 14 November 2026 UTC:

- **168/168 tests passed** on Apple Silicon (53.6 seconds of suite wall time).
- The universal executable contains **arm64 and x86_64**; **25/25 bundle checks** and
  **11/11 ZIP checks** passed, including all **180 game project files** and imported assets.
- Exported-app self-tests passed headlessly and with a window on Apple Silicon.
- Fresh jobs downloaded and launched the ZIP successfully: Apple Silicon passed headless
  and windowed checks; Intel passed headless. Intel windowed rendering is not verified.
- Apple Silicon reported macOS 26.7.2, Apple M1 (Virtual), Apple Paravirtual device (Apple5),
  Forward+ / Metal. Metal emitted its existing sampler LOD-bias warning; self-tests found
  no engine errors. This virtual machine is not the user's physical M1.
- Optional Developer ID signing/notarization was skipped.

The subsequent door-regression fixes and evidence are checked by the same workflow.
[PR #3 checks](https://github.com/oiwdis/last-train-out/pull/3/checks) show the latest commit's
result. Download **LastTrainOut-macos-universal.zip** from the latest successful run there;
the final delivery also links that run and its artifact directly.

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
