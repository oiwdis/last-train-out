# Milestone 3 — The Advancing Fog

Branch: `feature/milestone-3-advancing-fog`. Base: completed M2.5 `8cde10cf78c1ea0cf7f7bafb5fc146d2e12514c2`. No M2.6 work was merged, rebased, cherry-picked or modified.

Implemented: route-driven advancing danger; four proximity states; seeded, warned environmental events; individual exposure/health/recovery; door-aware shelter; minimal fuel pressure and stored-coal refueling; survival HUD/F3 diagnostics; original layered audio; distance-limited fog sheets and haze; clues; serializable survival authority; existing train/scavenging/FP/TP compatibility.

- [Architecture and M2.6 integration](FOG_ARCHITECTURE.md)
- [Tuning and rationale](FOG_BALANCING.md)
- [Coverage and gameplay method](FOG_VALIDATION.md)
- [Measured performance](PERFORMANCE_MILESTONE3.md)
- [Raw validation](validation/milestone3)
- [Screenshots](screenshots/milestone3)
- [113-second gameplay recording](recording/milestone3_survival.mp4) · [capture method](recording/milestone3_survival.md)
- [PR #5, final CI and universal macOS download](https://github.com/oiwdis/last-train-out/pull/5)

## Validation status

Godot **4.5.1** Linux baseline: **168/168**. Updated full suite: **214/214** (46 additional fog tests), plus import and 600-frame scene smoke. The two obsolete placeholder assertions were updated to expect real fog behavior; existing gameplay cases remain. Raw logs/reports are committed under `docs/validation/milestone3`.

Coverage includes route movement/segments/curves, danger boundaries, escalation, surge timing, calm/dense behavior, event determinism, difficulty, malformed saves, JSON continuation, independent doses, health/recovery, shelter doors/roofs, existing train escape and stopped catch-up, reverse progress, moving-train exit, live search, heavy cargo, death/restart, fuel/refueling, graphics independence, FP/TP and station-transition APIs.

Graphical validation: **60/60 scenario checks passed** in the actual recorded scene; nine screenshots and the complete 113.125-second recording are committed. The movie shutdown reported an ObjectDB cleanup warning, documented in the capture notes. This was a scripted demonstration with explicit setup cuts, not independent human playtesting.

The initial macOS [run 18](https://github.com/oiwdis/last-train-out/actions/runs/43758080250) passed the 211-test implementation, universal export, bundle/ZIP checks, Apple Silicon exported/fresh-download headless/windowed launches and Intel fresh-download headless launch. Final-source CI and downloadable ZIP links are maintained in [PR #5](https://github.com/oiwdis/last-train-out/pull/5), so build IDs are not embedded into the source commit they validate. Match the run's head SHA to the reported source revision. The preserved workflow now requires 214 tests and six additional exported survival checks; optional signing/notarization is unchanged.


## Explicit limitations

- Harlow Junction is still the only authored station, with the baseline's finite straight train track. Curved-route fog and station transitions are tested APIs, not newly built curved railway content or a playable second stop.
- No complete game save/load UI, multiplayer, branch-front propagation, combat, healing or enemies. Survival snapshots require the future world save to persist actors, train and inventories too.
- Boundaries use economical translucent sheets and observer haze; not volumetric sculpting or photorealistic replacement assets. No humanoid silhouette assets.
- Difficulty/seed are configurable resources, not new player-facing mission selectors.
- Physical Apple Silicon performance and human play feel remain unverified. Linux software rendering is not an M1 result. Hosted Mac evidence, when available, is labeled as such.
- The PR remains a draft because the complete requested between-station campaign loop is not implemented on the one-station baseline, even when all build/scenario checks pass.
