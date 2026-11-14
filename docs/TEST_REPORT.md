# Test report — Milestone 1.5

## Automated baseline and regression results

The unmodified development branch at `10bf758` passed **102/102** tests using the official
Godot **4.5.1-stable** Linux x86_64 build and Jolt. After the visual/UI overhaul,
**114/114** pass: the original 102 plus 12 presentation regressions. Import and the
600-frame headless main-scene smoke test also pass with no engine/script errors.

The final local run took 23.7 seconds of wall time for the test suite. This measures
fast-forward testing, not gameplay frame rate. The test runner and original tests are
unchanged. The macOS workflow now requires at least 114 passing tests.

New coverage checks:

- Actual parked/departing/cruising/braking/stopped train states and reset; a train stopped
  away from the platform is not incorrectly labelled as parked there.
- Ground/upper-floor, trackside, back-room, freight-yard and onboard location labels.
- Sustained boarding contact, a single confirmation and its expiry.
- Interaction prompts agreeing with the player's real eligibility and attached controls.
- Explicit exhaustion text, recovery, message fades and safe HUD rebinding.
- Front and rear decorative meshes hiding with their walls, then restoring on exit.
- No collision objects or lights inside new detail groups; bounded decorative mesh count.
- Landing feedback leaving the player's body scale, movement configuration and camera
  profile unchanged.

The existing interpolation tests still report **0.00000 m** relative drift and jitter for
both the train rider and attached climber. All full-station traversal, coyote-time,
jump-buffer, ladder/railing, moving-platform and reset tests still pass.

## Reproduction

```bash
tools/run_tests.sh /path/to/Godot_v4.5.1-stable
```

Reports are written to `tests/_output/`. On a sandbox with a read-only home directory,
set `XDG_DATA_HOME`, `XDG_CONFIG_HOME` and `XDG_CACHE_HOME` to writable scratch directories.
The environment's preinstalled Godot 4.6.3 could not write its default data directories;
all reported baseline and final verification used 4.5.1 with writable XDG directories.

## Graphical evidence

The final evidence is captured from the running game, with the original ten camera
placements and scripted actions. The overview alone uses a detached camera and thinner
fog, just as in Milestone 1. Originals are preserved in `screenshots/before/`.

`tools/capture_screenshots.tscn` accepts an optional `--fast` switch. It runs the same
physics/settle intervals without drawing intermediate frames, then draws eight settling
frames before saving each image. This is useful on a software renderer; it does not
measure motion smoothness. Movie Maker does not use this shortcut.

```bash
godot --path . --fixed-fps 60 tools/capture_screenshots.tscn -- --fast --out=docs/screenshots
godot --path . --rendering-method gl_compatibility --resolution 960x540 \
  --write-movie /tmp/demo.avi --fixed-fps 24 tools/record_demo.tscn
ffmpeg -i /tmp/demo.avi -c:v libx264 -crf 22 -pix_fmt yuv420p \
  -movflags +faststart -an docs/recording/milestone1_5_demo.mp4
```

Captures use Xvfb and Mesa software rendering on Linux. Forward+ is exercised with
lavapipe; desktop Compatibility is exercised with llvmpipe. The recording includes
movement, both warehouses, freight-yard climbing, jump boarding, moving-ladder boarding
and riding through building cutaways. It uses real scripted player input for actions,
and explicitly teleports between tour locations. It is not a human playtest.

The [updated recording](recording/milestone1_5_demo.mp4) contains **1,408 frames at 24 FPS**
(58.67 seconds, 960 × 540, H.264). The script completed with `aboard the train: true`,
reported no failed route steps, and the encoded file decoded fully without errors.
Sampled frames were reviewed for movement, both warehouse interiors, jump boarding,
ladder boarding and the final roof ride. Movie Maker took 8 minutes 26 seconds to render
on the shared software GPU; the output's 24 FPS is a capture setting, not measured game
performance.

## macOS export verification

The existing Godot 4.5.1 universal export, bundle validation, ad-hoc signing, app self-test,
ZIP validation and downloaded-artifact checks are preserved. The workflow now also runs
on pull requests targeting `claude/serene-turing-0vpdmt`, so this milestone can be tested
and downloaded before merging. Developer ID signing remains manual and optional.

[macOS app run #5](https://github.com/oiwdis/last-train-out/actions/runs/43550493035)
passed for implementation commit `eeac435` on 14 November 2026 UTC:

- **114/114 tests passed** on macOS with Godot 4.5.1 (15.3 seconds of suite wall time).
- Exported a universal executable containing **arm64 and x86_64**; all **25 bundle checks**
  and **11 ZIP checks** passed, including all 94 game project files in the pack.
- The exported app passed both headless and windowed self-tests on Apple Silicon.
- Fresh jobs downloaded and unzipped the artifact: Apple Silicon passed both launch modes;
  Intel passed its headless launch. The Intel windowed check is intentionally skipped.
- The optional Developer ID/notarization job was not requested and was skipped.

The [universal app artifact](https://github.com/oiwdis/last-train-out/actions/runs/43550493035/artifacts/14096090579)
is approximately 63.5 MB and requires GitHub sign-in. Artifacts expire after 30 days;
the [workflow page](https://github.com/oiwdis/last-train-out/actions/workflows/macos-app.yml)
has subsequent builds. This run verifies the complete implementation; the follow-up
evidence commit changes documentation, screenshots and the recording only.

## Remaining limitations

- **60 FPS on a real MacBook Air is unmeasured.** Software-rendered captures and Movie
  Maker output cannot establish real-time GPU performance.
- **No human has playtested this update.** Automated input, routing and screenshots do
  not establish how movement feels with real hardware.
- GitHub's Apple Silicon GPU is virtual. The original capability check still disables
  unsupported volumetric fog there. Haze on a real Mac remains unverified.
- GitHub's Intel runner tests the app without a window; Intel rendering remains unverified.
- Development exports are ad-hoc signed, not Developer ID signed/notarized. The existing
  macOS download instructions and optional signing workflow still apply.
- Train interiors are visual only; boarding uses roofs, decks, ladders and railings.
- Named HUD zones and procedural dressing are authored for Harlow Junction. Art is
  generated when the scene runs; a future station needs its own zones and dressing.
- Fog surge, passengers, inventory, damage, audio and saving remain outside this milestone.

The historical baseline report is preserved in
[MILESTONE_1_TEST_REPORT.md](MILESTONE_1_TEST_REPORT.md).
