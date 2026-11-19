# Milestone 3.5.1 release review

Continue [draft PR #6](https://github.com/oiwdis/last-train-out/pull/6); do not merge automatically.
The complete integrated game is retained. Reference commit:
`7df2f5abee54b8adcf27b8668263fba231a79033`.

## Changes

- Keep procedural mesh construction on CPU until final upload, removing repeated GPU readbacks.
- Prepare each authored view through a GPU queue rotation and drain the restored camera before gameplay resumes.
- Reuse the stamina HUD style instead of uploading unchanged polygons every frame.
- Own preparation by the scene, resolve cancellation and free its temporary resources.
- Batch MoltenVK PSO cache serialization until clean shutdown for the observed working set.
- Retain raw startup/frame timelines, partial failed matrices, all outliers and repeated-process stress evidence.
- Wait for stopped audio playbacks to retire from the mixer before diagnostic shutdown.
- Fail automated/exported diagnostics on retained-resource warnings rather than accepting only a zero exit.

[Performance analysis](PERFORMANCE_MILESTONE351.md) distinguishes proven causes,
measured improvements and unresolved driver behavior. [Physical M1 procedure](M1_MILESTONE351.md)
remains pending; no physical 2020 M1 is connected.

## Regression coverage

All 292 original test identities remain mandatory. Eight new tests bring the
suite to 300; external renderer/startup/export checks are additional checks,
not inflated into that unit/integration test count.

| Requested area | Coverage |
|---|---|
| Preparation ordering / startup initialization | Scene-owned job, native startup phase probes, rendered lifecycle suite, existing journey-ready guards |
| Scene-entry stalls | All 12 locations × 3 presets; separate entry and steady raw intervals, no dropped outliers |
| Fog material initialization | Material/shader identity across four danger states and all three presets; exposure/RNG snapshots unchanged |
| Preset switching | Rapid Low/Medium/High requests, last-quality completion, repeated rendered full matrices |
| Repeated scene loading | Per-test scene teardown, native lifecycle suite, actual Save/Continue reload, repeated processes |
| Save/resume during preparation | Native-rendered rider and loose-cargo restoration regression during active preparation |
| Player and cargo restoration | New preparation regression plus existing synchronization race test and cold moving-world resume |
| Renderer ownership / shutdown | Weak-reference cancellation, cache release/rebuild, strict ObjectDB/resource-in-use checks, repeated native shutdowns |
| Shader cache behavior | Repeated native process traces and `verify_startup_cache.py`; persisted PSO reuse and cold/warm shader misses |
| Mission completion/failure | Continuous 167-check journey, 24-check natural fog death, existing mission-state suite |
| Graphics compatibility | All presets, first/third-person export checks, native rendered lifecycle checks; physical M1 pending |
| Missing assets / exported integrity | Existing 31-model/137-texture validator, full pack inventory, universal architecture/signature/bundle/ZIP verification |

## Current evidence

Linux Godot 4.5.1/Jolt: **300/300**, 143.7 seconds, no ObjectDB/resource-in-use
diagnostics. Latest controls-driven journey **167/167**, fuel recovery **35/35**,
natural fog failure **24/24**, separate-process moving save **17/17**. Zero travel
teleports; one legitimate Blackwater save restoration. Headless/fixed-step runs
are functional validation, not real-time rendering performance.

The final native [run 44583413439](https://github.com/oiwdis/last-train-out/actions/runs/44583413439) passed 300/300 in 161.8 seconds, five Vulkan lifecycle tests, all gameplay scenarios, universal export, packaged ARM launches, fresh-download ARM/Intel checks and 81 packaged diagnostics. The new continuous recording passed 167 checks. See [complete release evidence](validation/milestone351/final-native/README.md) and the [all-location matched comparison](validation/milestone351/final-native/comparison/COMPARISON.md).

## Acceptance status

The multi-second Harlow entry stall is substantially reduced (High 2393.057 → 89.192 ms; Medium 1866.183 → 65.721 ms). The complete 100 ms entry target remains unmet: High Warehouse A reaches 168.372 ms. Warm startup improves to 18.579/19.052 seconds but remains above the next milestone's 15-second target. Several steady cases regress, including High Warehouse B p99 34.907 → 63.724 ms. All unfavorable samples remain in the report.

Coroutine and audio-retirement fixes survive the full recording and exported/fresh-download diagnostics without ObjectDB or resource-in-use warnings. The verbose engine `servers` StringName remains documented. The historical fatal Vulkan timeout is investigated but not proven fixed. Physical 2020 M1 acceptance remains a blocker.

The [new 23:28 continuous recording](recording/milestone351-full-journey.mp4) and [universal development ZIP](https://github.com/oiwdis/last-train-out/actions/runs/44583413439/artifacts/14564792174) are available. Movie Maker's 12 FPS capture is not real-time performance; the build is ad-hoc signed and not notarized.

Keep PR #6 in draft. Functional/release CI passes, but performance and physical-device acceptance remain open. Milestone 3.5.2 continues from this result.
