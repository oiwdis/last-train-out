# Test report — Milestone 2

## Baseline and regression results

The completed visual-overhaul branch at `7571753` passed **114/114** tests with official
Godot **4.5.1-stable** on Linux x86_64, Jolt and 60 Hz physics. The Milestone 2 implementation
passes **147/147**: all 114 original tests unchanged, plus 33 new tests. Import and the
600-frame main-scene smoke test pass without engine/script errors. The local full suite took
31.3 seconds of wall time; this is accelerated test execution, not gameplay FPS.

| New suite | Tests | Coverage |
|---|---:|---|
| Inventory unit | 10 | All nine definitions, limits, six slots, heavy rejection, snapshots, partial transfers, reentrant signals, 500 transfer cycles and seeded loot |
| Scavenging integration | 10 | All thirteen cache approaches using the real interaction selector, both warehouses, search/cancel, overflow, drop/recovery, one-time heavy spawns, storage range and reset |
| Carrying integration | 8 | 2.5 m/s, no sprint, unchanged unladen config, one-object limit, ladder/vault feedback, jump boarding, loose-cargo riding/reset and conservation |
| UI and graphics integration | 5 | Keyboard/mouse ledger controls, tooltips, immediate storage updates, physics isolation across presets and 2560×1600 resolution budgets |

Existing traversal, jump timing, climbing, moving train, collision and interpolation tests
remain intact. Rider/climber interpolation still reports zero measured relative drift and
jitter in those tests. No test-runner assertion was weakened and CI requires at least 147 tests.

The app self-test now also searches a real cache, deposits and withdraws supplies, checks
conservation, holds/releases cargo, switches all three presets and opens the inventory. Its
headless source-project run passed all checks with no engine errors. The scripted evidence
tour also passed: 12 supplies secured aboard, including one machine component, with an empty
backpack after the final deposit and no failed route steps.

## Reproduction

```bash
tools/run_tests.sh /path/to/Godot_v4.5.1-stable
/path/to/Godot_v4.5.1-stable --headless --path . --fixed-fps 60 \
  scenes/main/self_test.tscn -- --selftest-report=/tmp/selftest.json
```

Logs are in `tests/_output/`. Use writable XDG data/config/cache directories in a sandbox.
All reported baseline and final results use the supported 4.5.1 build, not the environment's
preinstalled newer Godot. UI tests exercise input handling and real models; screenshots below
supply the separate visual check.

## Graphical evidence

Eight [screenshots](screenshots/milestone2/) show searches in both warehouses, the six-slot
backpack, held and dropped cargo, the train hold and Low/High rendering. Captures come from
Forward+ under Linux Xvfb with Mesa lavapipe. They use the normal camera and UI, with explicit
teleports between tour locations. No screenshots have been painted or composited.

```bash
godot --path . --audio-driver Dummy --resolution 1280x720 --fixed-fps 60 \
  tools/capture_milestone2.tscn -- --fast
godot --path . --audio-driver Dummy --rendering-method gl_compatibility \
  --resolution 960x540 --write-movie /tmp/milestone2.avi --fixed-fps 24 \
  tools/capture_milestone2.tscn -- --out=/tmp/video-captures
ffmpeg -i /tmp/milestone2.avi -c:v libx264 -crf 22 -pix_fmt yuv420p \
  -movflags +faststart -an docs/recording/milestone2_tour.mp4
```

The `--fast` screenshot option suppresses intermediate drawing and renders eight settling
frames at each capture. The recording does not use it. Actions use real searches, inventory
transactions and cargo objects; location changes are scripted tour cuts. These are automated
observations, not a human playtest, and Movie Maker's frame rate is not measured performance.
The [performance report](PERFORMANCE.md) uses a separate real-time benchmark.

The [recording](recording/milestone2_tour.mp4) contains **951 frames at 24 FPS**, **39.625 seconds**,
960×540 H.264, without audio. It completed every route step and its final conservation report
showed 12 supplies secured aboard. The entire encoded file decoded without errors; sampled
frames were checked for searches, the inventory, carrying, drop/recovery and the storage ledger.
The Compatibility renderer used Mesa llvmpipe; its driver emitted a VSync-control warning.
The capture frame rate is a Movie Maker output setting, not gameplay FPS.

## macOS export verification

The existing universal export, ad-hoc signing, bundle/ZIP validation and downloaded-app tests
remain. The pack verifier includes new SVG icon imports. Pull requests targeting the completed
visual-overhaul branch run the same pipeline before merging. Developer ID signing/notarization
remains optional and manual.

[macOS app run #7](https://github.com/oiwdis/last-train-out/actions/runs/43559838372)
passed for implementation `0146f29` (PR merge checkout `edc2b1f`) on 14 November 2026 UTC:

- **147/147 tests passed** on Apple Silicon macOS with Godot 4.5.1 (31.5 seconds of suite wall time).
- The universal executable contains **arm64 and x86_64**. All **25 bundle checks** and
  **11 ZIP checks** passed, with all **138 game project files** present, including the icons.
- Both headless and windowed exported-app self-tests passed on Apple Silicon.
- Fresh jobs downloaded the ZIP, verified it and launched it: Apple Silicon passed headless
  and windowed checks; Intel passed headless on macOS 15.7.9 / Core i7-8700B. Intel windowed
  rendering is intentionally skipped.
- Apple Silicon reported macOS 26.7.2, Apple M1 (Virtual), Apple Paravirtual device (Apple5),
  Forward+ / Metal. The engine reported its existing Metal sampler LOD-bias warning; no engine
  errors or failed self-test checks occurred. This VM is not the user's physical M1.
- Optional Developer ID signing/notarization was not requested and was skipped.

[Download the universal app](https://github.com/oiwdis/last-train-out/actions/runs/43559838372/artifacts/14099838445)
(63.6 MB, GitHub sign-in required). SHA-256:
`a5172d46e9b55b97ff5842462f9e5cb470c55e37bd4527cedd20e60eee9966be`.
This run verifies the implementation; the following evidence/documentation commit preserves
its gameplay behavior. The PR checks show the latest run.

## Remaining limits

- The user tested Milestone 1.5 full-screen on a 2020 M1 Mac and approved the movement. This
  update has not been human-playtested there. Its macOS version and display resolution are
  unspecified. There is no measured M1 FPS improvement claim.
- Linux rendering uses software Vulkan/OpenGL. GitHub Apple Silicon rendering uses a virtual
  GPU; unsupported volumetric fog remains guarded. Intel CI launches headlessly, so it does
  not establish Intel graphical performance or correctness.
- Development downloads are ad-hoc signed, not notarized; the existing first-launch macOS
  instructions still apply. Artifacts require GitHub sign-in and expire after 30 days.
- Supplies reset on relaunch; only the graphics preference persists. Heavy objects do not
  collide with each other or block the player. Train interiors remain visual only.
- Advancing dangerous fog, damage, consumption, healing, crafting, passengers, combat, train
  upgrades, additional stations and full save/load are outside this milestone. Audio is absent.

Historical reports: [Milestone 1.5](MILESTONE_1_5_TEST_REPORT.md) and
[Milestone 1](MILESTONE_1_TEST_REPORT.md).
