# Milestone 3 — The Advancing Fog

Branch: `feature/milestone-3-advancing-fog`. Base: completed M2.5 `8cde10cf78c1ea0cf7f7bafb5fc146d2e12514c2`. No M2.6 work was merged, rebased, cherry-picked or modified.

Implemented: route-driven advancing danger; four proximity states; seeded, warned environmental events; individual exposure/health/recovery; door-aware shelter; minimal fuel pressure and stored-coal refueling; survival HUD/F3 diagnostics; original layered audio; distance-limited fog sheets and haze; clues; serializable survival authority; existing train/scavenging/FP/TP compatibility.

- [Architecture and M2.6 integration](FOG_ARCHITECTURE.md)
- [Tuning and rationale](FOG_BALANCING.md)
- [Raw validation](validation/milestone3)
- [Screenshots](screenshots/milestone3)

## Validation status

Godot **4.5.1** Linux baseline: **168/168**. Updated full suite: **211/211** (43 additional fog tests), plus import and 600-frame scene smoke. The two obsolete placeholder assertions were updated to expect real fog behavior; existing gameplay cases remain. Raw logs/reports are committed under `docs/validation/milestone3`.

Coverage includes route movement/segments/curves, danger boundaries, escalation, surge timing, calm/dense behavior, event determinism, difficulty, malformed saves, JSON continuation, independent doses, health/recovery, shelter doors/roofs, existing train escape and stopped catch-up, reverse progress, moving-train exit, live search, heavy cargo, death/restart, fuel/refueling, graphics independence, FP/TP and station-transition APIs.

Graphical gameplay recording, performance comparison and macOS CI results are being collected; no success is claimed until linked evidence exists. The preserved macOS workflow adds six exported survival checks and still exports a universal app, checks bundle/ZIP integrity, runs Apple Silicon headless/windowed and fresh-download checks, and Intel headless validation. Optional signing/notarization remains unchanged.

## Explicit limitations

- Harlow Junction is still the only authored station, with the baseline's finite straight train track. Curved-route fog and station transitions are tested APIs, not newly built curved railway content or a playable second stop.
- No complete game save/load UI, multiplayer, branch-front propagation, combat, healing or enemies. Survival snapshots require the future world save to persist actors, train and inventories too.
- Boundaries use economical translucent sheets and observer haze; not volumetric sculpting or photorealistic replacement assets. No humanoid silhouette assets.
- Difficulty/seed are configurable resources, not new player-facing mission selectors.
- Physical Apple Silicon performance and human play feel remain unverified. Linux software rendering is not an M1 result. Hosted Mac evidence, when available, is labeled as such.
- Final screenshots/video/build links and measured performance are pending in this initial review commit. The PR remains a draft until validation evidence is attached; incomplete world progression remains stated even after those checks succeed.
