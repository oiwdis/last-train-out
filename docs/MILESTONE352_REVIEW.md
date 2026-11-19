# Milestone 3.5.2 release review

Keep [PR #6](https://github.com/oiwdis/last-train-out/pull/6) in draft. Physical
2020 M1 acceptance is unavailable and remains a blocker. The final candidate also
reproduced fatal Vulkan device loss during fresh-download ARM validation. The performance target
is responsive gameplay with consistent frame pacing; passing functional CI is
not performance acceptance. No automatic merge is authorized.

Runtime under validation: `6038bfcd0f0c5427ae6c53435d2867282938f6e4`.
[Performance report](PERFORMANCE_MILESTONE352.md),
[raw native evidence](validation/milestone352/final-native/README.md), and
[owner's physical M1 procedure](M1_MILESTONE352.md).

## Change scope

The existing CPU geometry, queue-aware preparation, HUD invalidation and PSO
cache fixes are retained. This continuation adds preparation coverage for the
exact Warehouse A interior and both train interiors; adopts real audio-owner
retirement in test fixtures; and fixes the pending spatial playback ownership
order when exiting before its first physics update. Detailed assets, fog rules,
station travel, save format and the Low/Medium/High distinctions are preserved.
No intended visual compromise requires new before/after art screenshots.

A fog-only preparation experiment failed with device loss in five of six
predefined attempts on two runners. It was rolled back, and every attempt is
retained. The historical Vulkan risk is not declared fixed by the rollback or
by a successful later workflow.

## Coverage

All original 300 test identities are mandatory. Four meaningful additions bring
the suite to 304: camera/material preparation contract, spawned-fixture audio
retirement, cleanup deadline/update ordering, and pending spatial playback
retirement. The two latter cases and fixture ownership test failed before their
fixes. External lifecycle, journey and packaged checks remain separate counts.

The final Linux suite passed 304/304 in 138.9 seconds; macOS passed 304/304 in
100.4 seconds. Six rendered lifecycle regressions passed in 128.7 seconds,
including Continue during preparation with rider and loose cargo together.
The new continuous recording passed all 167 journey checks. Export, bundle/ZIP
integrity and build-runner ARM launches passed. Fresh Intel headless passed, but
**fresh ARM windowed launch failed with Vulkan device loss during presets**. Its
headless launch passed; the subsequent 81-case packaged diagnostic was skipped.
[Run 44608806260](https://github.com/oiwdis/last-train-out/actions/runs/44608806260)
retains this failed gate. The completed 31-process exported series has 29
successes and two cold High device losses; all ten cold and ten warm launches
were attempted, with no retry or skipped attempt. All lifecycle scenarios passed.
Both native crash reports are retained. Exported successful cold readiness ranges
from 21.875 to 89.107 seconds and warm readiness from 16.466 to 20.564 seconds.

## Acceptance boundaries

- Physical M1 fullscreen and normal-play performance require the owner procedure.
- Source-project and exported baked-shader launches are separate populations.
- The initial native source probes took 59.688 / 20.019 / 15.774 seconds; these
  remain included even if the matched cohort or exported app is faster.
- The progress overlay covers render preparation after loading. The earlier
  engine/resource loading interval is synchronous and is not claimed fully
  responsive.
- GPU timestamps, material switches and isolated shadow-pass timing are not
  exposed on this hosted runner. CPU callback brackets include waits.
- The continuous Movie Maker recording uses fixed offline capture timing and
  cannot establish real-time FPS or wall-clock responsiveness.
- Engine `servers` StringName and MoltenVK allocation-at-destruction information
  remain in logs. They are distinguished from reproduced game resource owners.

## Measured remaining performance gaps

High Harlow entry falls from 2,404.751 to 96.794 ms, but the all-location worst
entry is 164.593 ms and Medium dangerous fog reaches 389.657 ms. Warm source
readiness is 19.132 / 17.335 seconds. Most pooled steady distributions regress;
both candidate attempts remain included. The new Warehouse A preparation view
does not eliminate its seven High-entry shader specializations. These facts
block performance acceptance even before physical M1 testing. See the report
for all locations, unfavorable measurements and the smallest next actions.
