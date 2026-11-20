# Milestone 3 validation map

Historical report for the original one-station fog implementation. The expanded journey, full save UI and current evidence are in [Milestone 3 finalization validation](MILESTONE3_FINALIZATION_VALIDATION.md).

Engine: official Godot 4.5.1. Completed Linux baseline: **168/168**. Final source suite: **214/214**, including 46 new fog cases, import and a 600-frame main-scene smoke. The last local full run took 88.1 seconds. Two obsolete placeholder assertions now test actual fog state and warning behavior. Logs and JSON summaries are in [validation/milestone3](validation/milestone3).

| Requested coverage | Executed coverage / limit |
|---|---|
| 1. Front movement | Exact movement; zero, negative, NaN/infinite delta; partitioned elapsed time |
| 2. Route segments | Continuous front crossing from west segment into bend |
| 3. Curved railway | Curve3D sample/projection and segment hint; actual baseline train remains straight |
| 4. Four danger states | Inclusive boundaries and deep fog; actual game HUD/state |
| 5. Escalation | Minute increment and speed cap |
| 6. Sudden surge | Full warning, acceleration factor, expiry, rejected stacking |
| 7–9. Dose, recovery, damage | Time/depth/difficulty, grace threshold, exact damage, no free health regeneration |
| 10. Shelter | Actual cab/crew doors, roof exclusion, leaking buildings, eventual sheltered death |
| 11–12. Train escape/catch | Existing train integrator escapes; stopped train is engulfed |
| 13. Difficulty | Speed and dose scaling |
| 14. Graphics independence | Same authority snapshot across Low/Medium/High; different sheet budgets |
| 15. Seeded events | Matching sequences/front over 1,200 s, different frame partitions |
| 16. Scavenging | Search continues under exposure; heavy cargo limit, drop, ownership; baseline stack/storage tests |
| 17. Train compatibility | All original movement/riding/traversal tests retained; fuel adapter uses start/stop |
| 18. FP/TP | Exposure continues while switching; native window inspection; baseline camera suite |
| 19. Save state | JSON survival-state continuation, RNG strings, corrupted-save rejection, dead/live restoration; no complete game-save UI |
| 20. Station transitions | Registered destination change preserves time/front and pending surge; no second authored station |

Edge cases also cover reversing supplied route progress (the baseline controller has no reverse driving), leaving a moving car, boarding with existing exposure, dying with heavy cargo, position resets without healing, and two registered survivors with independent dose/disconnect behavior.

## Gameplay evidence method

`tools/validate_fog_gameplay.tscn` loads the real main scene. RouteBot steers through scripted PlayerInput, actual collisions, vaults and ladder interactions. Searches/pickup/regulator use E through the camera reticle. The Warehouse B return, roof-to-gangway descent, departure and recovery contain **no teleports, clock skips or fog-front edits** after their initial setup. State assertions fail the run if an action did not occur.

The complete headless rehearsal and the graphical recording each passed **60 checks** at 24 FPS. Scenario setup cuts are printed/captioned: normal scavenging includes a cab boarding cut; late Warehouse B starts at front -14 m; heavy coal starts at -12 m; fuel shortage uses 0.4 fuel; deliberate exposure starts at +5 m. These accelerate scenario setup rather than disguising several minutes of waiting. The committed `gameplay.json` records `headless: false`, the logical canvas size and all graphical outcomes. The recorded boarding clearance was -3.329 m.

- A: two platform caches searched, supplies kept, normal cab departure while healthy.
- B: a heavy machine component discovered in Warehouse B and left behind; uninterrupted physical return/boarding/regulator escape. In the recording, train-stop clearance was **-3.329 m at boarding**.
- C: actual coal reserve searched, sack picked up, carry speed limited, then cargo abandoned/recoverable.
- D: moving train exhausts the almost-empty boiler; empty restart rejected while fog continues.
- E: deliberate boundary exposure causes progressive health loss.
- F: train travels more than 190 m with a persistent pursuing front. This is travel along the baseline line, **not between two authored stations**.
- G: exposure clears after escape on the train and after retreating on foot; health loss remains.

The 113.125-second recording is an offline 24 FPS Godot Movie Maker render with Low/Compatibility. Movie Maker emitted an ObjectDB cleanup warning after completing all checks; the full scene/test suite reported no engine errors. It is not an FPS benchmark or an unscripted human playtest. Native desktop inspection separately confirmed the HUD in both perspectives. Screenshots are direct game viewport captures, with no visual editing. Audio is synthesized in the project and captured in the recording; listening quality has not been human reviewed.

## CI and scope

The macOS workflow retains universal arm64/x86_64 export, ad-hoc signature/bundle/ZIP checks, exported-app and fresh-downloaded Apple Silicon headless/windowed checks, Intel headless checks, and optional Developer ID/notarization. Six additional exported survival checks cover authority/HUD presence, advancement, damage, snapshot restoration, empty fuel and new-run reset.

The initial source CI [run 18](https://github.com/oiwdis/last-train-out/actions/runs/43758080250) passed all jobs with 211 tests. Final-source build evidence is linked in the PR after the evidence commit. Do not use the initial build as proof of subsequent changes. Physical 2020 M1 performance, Intel graphical rendering, notarization and independent human play feel are not verified by this work.
