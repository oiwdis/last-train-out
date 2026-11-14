# Test report - Milestone 1

This report states what was tested, how, what the results were, and what could
**not** be verified. Read the "Not verified" section before relying on the
build: the project has never been run on macOS or played by a person.

## Summary

| | Result |
|---|---|
| Automated tests | **102 passed, 0 failed** (10 test files) |
| Project import, headless | no errors |
| Main scene, 600 frames headless | no errors |
| Main scene opened in the editor (headless) | no errors from the `@tool` scripts |
| Same tests on GodotPhysics3D instead of Jolt | 102 passed, 0 failed |
| Same tests on Godot 4.7 | 102 passed, 0 failed |
| Screenshots | 10 captured from the running game |
| Recording | 48 s scripted playthrough captured from the running game |
| macOS app build (GitHub Actions) | tests, export, bundle checks and self-test launches pass - see "macOS build pipeline" |
| macOS / Apple Silicon | tests and the exported app run in CI on a virtual Apple Silicon Mac; **not tested on a real Mac** |
| macOS / Intel | the app's Intel half runs in CI without a window; **rendering on Intel not tested** |
| Played by a human | **not tested** |
| Frame rate on real hardware | **not measured** |

## Environment

Everything below ran in a Linux x86_64 cloud container (Ubuntu 24.04, 4 CPU
cores, no GPU, no audio device, no physical input devices).

| Item | Value |
|---|---|
| Godot (primary) | 4.5.1-stable, official Linux build |
| Godot (compatibility check) | 4.7-stable, official Linux build |
| Physics engine | Jolt Physics (project setting); GodotPhysics3D as a cross-check |
| Test mode | `--headless --fixed-fps 60` (real physics, no rendering) |
| Rendering for captures | Forward+ on Mesa lavapipe (software Vulkan) under Xvfb. The Compatibility renderer (software OpenGL) was also exercised during development. |

## How to reproduce

```bash
tools/run_tests.sh /path/to/godot
```

This imports the project, runs the main scene for 600 frames and runs all
tests. Logs and a JSON summary are written to `tests/_output/`.

## Automated tests

All tests run the real scenes with the real physics engine. The player is
driven through `PlayerInput`'s scripted hook (the same fields the keyboard
fills in); one suite drives it with simulated physical key events instead.
Any engine or script error during a test fails that test, as does a test that
runs no assertions.

| Test file | Tests | Covers |
|---|---|---|
| `unit/test_project_integrity.gd` | 7 | Every script compiles (46), every resource loads (42), every scene instantiates (18); main scene setting; Input Map actions; physics layer names; player/train collision layers |
| `unit/test_stamina.gd` | 7 | Drain rate, no drain when not sprinting, regeneration delay and rate, exhaustion lock-out and recovery, reset |
| `unit/test_train_motion.gd` | 12 | The three departure modes, smoothness of acceleration, acceleration modifier, configurable and eased maximum speed, stop, stop/restart and mode change without speed jumps, reset, automatic braking at the end of the track |
| `integration/test_player_movement.gd` | 16 | Walk and sprint speed, responsiveness, state transitions, depth movement, jump height, short hop, no auto-repeat, sprint-jump length, stamina in play, exhaustion, **coyote time** (accepted and expired), **jump buffering** (executed and expired), player reset |
| `integration/test_moving_platform.gd` | 8 | Standing on the parked train, riding through acceleration and braking, walking on the moving deck, jumping on and off the train, reset with the player aboard and on the platform |
| `integration/test_traversal.gd` | 17 | Vault, climb onto, un-vaultable wall, static ladder up/down/jump off, re-grab cooldown, grabbing a moving ladder and climbing to the roof, speed limit on grabs, grabbing a railing (from the platform and from the ground), vaulting cargo on the moving car, jumping from the platform onto the moving car, walking onto a moving deck, being knocked off by an obstacle |
| `integration/test_render_smoothness.gd` | 2 | Rider and ladder climber sampled through physics interpolation (physics 30 Hz, frames 60 Hz) |
| `integration/test_station.gd` | 9 | Main scene start-up, station dimensions, end-to-end traversal, Warehouse A stairs / upper floor / balcony ladder, Warehouse B blocked doorway and back-room detour, freight-yard ladders / roofs / gaps, crossing times, the return run |
| `integration/test_station_systems.gd` | 17 | Cutaway walls (per building, fade, passing behind), camera zoom / smoothness / framing / departure widening, debug menu (toggle, train, player, station, diagnostics, input not stolen), system stubs, riding the roof and clinging to a ladder through the whole station, reset while clinging, player on the track bed |
| `integration/test_keyboard_input.gd` | 7 | Simulated physical key events for A/D, W/S, arrows, Shift, Space, E, F1, Esc, `` ` `` reaching the player and the debug menu through the Input Map |

### Measured values (Godot 4.5.1, Jolt)

| Measurement | Value |
|---|---|
| Emergency Steam: time to full speed / peak acceleration | 6.00 s / 3.00 m/s² |
| Normal: time to full speed / peak acceleration | 10.00 s / 1.80 m/s² |
| Slow Departure: time to full speed / peak acceleration | 16.00 s / 1.12 m/s² |
| Rider drift relative to the car while accelerating 0 → 12 m/s | 0.0000 m (limit 0.03 m) |
| Rider per-tick jitter relative to the car | 0.00000 m (limit 0.005 m) |
| Rider drift while braking 12 → 0 m/s | 0.0000 m |
| Rider drift, interpolated frames between physics ticks | 0.00000 m |
| Ladder climber drift, interpolated frames | 0.00000 m |
| Roof ride through the whole station (170 m, up to 12 m/s) | never knocked off, drift 0.0000 m |
| Jump straight up on the train at 12 m/s | apex 1.24 m, lands 0.000 m from take-off |
| Jump apex / air time (configured height 1.3 m) | 1.24 m / 0.63 s |
| Tapped jump apex | 0.27 m |
| Sprint jump length | 3.90 m |
| Largest camera movement in one tick while sprinting through a doorway | 0.172 m (limit 0.3 m; sprinting itself is 0.1 m per tick) |
| Platform → freight yard, scripted run | 19.6 s |
| Warehouse A / Warehouse B, door to door | 5.0 s / 7.2 s |
| **Return run: far end of Warehouse B → holding the train** | **19.0 s** (design target about 20 s) |

The return run is a scripted bot that sprints whenever stamina allows, vaults
two obstacles, takes the back-room detour and grabs the locomotive's ladder.
A person will be slower or faster depending on routing and stamina use.

### The brief's moving-platform checklist

| Step in the brief | Test |
|---|---|
| 1. The player starts on a stationary train | `test_player_stands_on_stationary_train` |
| 2. The train accelerates | `test_player_rides_accelerating_train_without_sliding` (Emergency Steam, the harshest mode) |
| 3. The player remains on the train for several seconds | same test: 8 s, never leaves the floor |
| 4. Position relative to the car stays within tolerance | same test: 0.0000 m drift |
| 5. The player jumps and inherits platform velocity | `test_jump_on_train_keeps_platform_momentum`, `test_jump_off_train_preserves_momentum` |
| 6. The train stops and resets without errors | `test_train_stops_smoothly_with_rider`, `test_reset_with_player_aboard` |

Headless mode runs the full 3D physics engine, so none of these checks is a
stand-in. What headless mode cannot show is how the result *looks and feels*;
see below.

## Graphical runs

These are automated runs with a real renderer, **not manual play-testing**.

- **Screenshots** (`docs/screenshots/`) were produced by
  `tools/capture_screenshots.tscn`: it loads the main scene, moves the player
  through scripted input, and saves the viewport. Ten images cover the six
  requested subjects (full station, train and platform, both warehouse
  interiors, the player boarding and riding the moving train, the debug menu)
  plus the upper floor, the back room, the freight yard and the ladder grab.
  The overview shot uses a detached camera and thinner haze so the far end of
  the station is legible; nothing else is staged.
- **Recording** (`docs/recording/milestone1_demo.mp4`, 48 s, 1280×720, 30 fps)
  was produced by `tools/record_demo.tscn` with Godot's Movie Maker mode. It
  shows walking, sprinting, jumping, a vault, ladder climbing and a gap jump in
  the freight yard, a Normal departure boarded by jumping onto the flat car
  with the debug menu's live diagnostics visible, and an Emergency Steam
  departure boarded by grabbing the passing ladder and riding the roof out of
  the station.

I looked at every screenshot and at sampled frames of the recording, and used
them to fix real problems during development (the player being hidden behind
tall racks and behind buildings while riding the train, the train blending
into the background, an over-dark Forward+ image).

Caveats:

- Movie Maker mode renders every frame regardless of how long it takes, so the
  recording shows correct motion but says **nothing about real-time
  performance**. The "FPS" value visible in the debug-menu captures (single
  digits) is the software renderer in this container and is not representative
  of any real machine.
- Software rendering can differ slightly from a GPU (filtering, shadow detail).

## macOS build pipeline

`.github/workflows/macos-app.yml` runs on GitHub's macOS runners on every push to the
development branch. Results of the runs made while setting it up:

| Step | Result |
|---|---|
| All automated tests on macOS 26 / Apple Silicon (Godot 4.5.1 editor, headless) | 102 passed, 0 failed |
| Export with Godot 4.5.1 and the official 4.5.1 export template (checksums pinned) | `Last Train Out.app`, 181 MB |
| Bundle checks | 25 of 25: `Info.plist`, executable present and universal (`arm64` + `x86_64`, confirmed by `lipo`), game data pack with all 89 project scenes/scripts/resources and nothing from tests/tools/docs, ad-hoc signature valid (`codesign --verify --deep --strict`) |
| Exported app launched on the runner, no window | 14 of 14 self-test checks |
| Exported app launched on the runner, with its window | 17 of 17 self-test checks; Forward+ on Metal, frame captured and not blank |
| ZIP made with `ditto` | 63.5 MB; 11 of 11 checks: holds exactly the bundle, file for file, executable bit kept |
| ZIP downloaded as an artifact, unzipped and launched on Apple Silicon | passed (without and with its window) |
| ZIP downloaded, unzipped and launched on an Intel runner | Intel half of the app passed the launch without a window |

The self-test (`scripts/main/self_test.gd`) runs inside the exported app, with no editor and
no project folder: it loads the real main scene, walks and jumps the player, puts the player
on the flat car, starts an Emergency Steam departure and checks the rider does not slide
(0.0000 m), checks the debug menu's live values, and fails on any engine error.

What this does **not** show:

- **GitHub's Macs are virtual machines.** Their GPU ("Apple Paravirtual device") cannot
  render volumetric fog; the first run crashed there until the game learned to check for the
  feature and skip the haze. So the windowed launch in CI runs *without* the volumetric haze,
  and the haze on real Mac hardware is still unverified.
- **Intel rendering is unverified.** The Intel runner has no usable GPU: opening a window
  there crashes in Vulkan pipeline creation, so that step is not run on Intel.
- The frame rate reported in CI (about 52 FPS on the virtual GPU) says nothing about a real Mac.
- Gatekeeper prompts were not observed: runners do not download through a browser, so the
  build is never quarantined there. The README describes the expected behaviour.
- **The signing job has not run with real credentials.** With no secrets configured it stops
  at its first step and lists what is missing.
- Nobody has opened the downloaded app on a real Mac or played it.

## Manual testing

**None was performed.** No person has played this build, and it has not been
run on macOS. The items below therefore rest on automated evidence only:

- Movement responsiveness and "feel" - timings are tested (walk speed reached
  within 0.15 s, turnaround within 0.3 s, coyote time and buffering), but
  whether it *feels* excellent needs a person at the keyboard.
- Warehouse navigation, ladder climbing, camera transitions, boarding, riding
  stability and reset behaviour - all pass their automated tests and look
  correct in the captures.

## Known issues and limitations

- **Jolt warning in fast-forward runs.** "Jolt Physics job system exceeded the
  maximum number of jobs" is printed occasionally when physics is stepped
  thousands of times per second (`--fixed-fps` headless runs, Godot 4.5.1 and
  4.7). It did not appear in real-time runs (0 of 2 runs) and has no effect on
  results. It is an engine message, not a project error.
- **Player on the track bed.** A player standing in front of the moving train
  is pushed along by it (tested: never ends up inside the train or below the
  ground). There is no damage or fail state yet.
- **End of the line.** The train brakes to a stop about 480 m past the
  station; the world out there is only track and background. Use the debug
  menu to reset.
- **Train interiors** are not enterable; the roof, decks, ladders and railings
  are the boarding surfaces.
- **Web export** has not been built or tested. The Compatibility renderer
  works with the project (volumetric fog is skipped there), but that was only
  exercised on desktop OpenGL.
- **Test framework** needs Godot 4.5+ (it uses the `Logger` class to catch
  engine errors).

## Not verified

- [ ] Running the app on a **real Mac** (CI covers virtual Apple Silicon and, without a window, Intel).
- [ ] Rendering on an **Intel Mac**, and the volumetric haze on any Mac.
- [ ] Developer ID signing, notarization and stapling (needs your Apple credentials).
- [ ] The Gatekeeper prompts for a downloaded development build.
- [ ] **60 FPS on a modern MacBook Air** - no measurement on any real GPU.
- [ ] Rendering with a real GPU / the Metal backend.
- [ ] Real keyboard hardware (key events were simulated at the Input Map level).
- [ ] How movement and boarding feel to a human player.
- [ ] Windows and web builds.

## Definition of done

"Automated" means covered by passing tests. "Captured" means also visible in
the screenshots or recording. Nothing here was verified by a person playing.

| Criterion | Status |
|---|---|
| The project opens successfully on macOS | **Unverified** (no macOS available). Opens, imports and runs on Linux with Godot 4.5.1 and 4.7 |
| The main scene runs without errors | Automated (headless, 600 frames, plus every station test) |
| The player can walk, sprint, jump, vault and climb | Automated, captured |
| Coyote time and jump buffering function | Automated |
| The player can traverse the full station | Automated (scripted run, platform → freight yard) |
| Warehouse A has functional stairs and two floors | Automated, captured |
| Warehouse B has a blocked route and a functional alternate path | Automated, captured |
| Freight car ladders are climbable | Automated (all five ladders in the yard), captured |
| The camera follows smoothly | Automated (no jump larger than 0.172 m per tick); smoothness on a real display **unverified** |
| Indoor/outdoor zoom transitions work | Automated, captured |
| Building cutaways work | Automated, captured |
| The train accelerates in all three departure modes | Automated |
| The player can jump onto the moving train | Automated, captured |
| The player can ride the train without significant sliding or jitter | Automated (0.0000 m drift, including interpolated frames), captured |
| The player can jump off the train correctly | Automated |
| The debug menu functions | Automated, captured |
| Automated tests pass | 102 / 102 |
| README documents controls, installation, debugging and structure | Done |
| Screenshots and/or recordings are supplied | Done (10 screenshots, 1 recording) |
| All implemented work is committed | Done |
