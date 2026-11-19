# Milestone 3.5.2 — performance acceptance

PR [#6](https://github.com/oiwdis/last-train-out/pull/6), existing integration branch. No automatic merge. Initial head `cc50670c9ae70aa2de7ce92185a229d284c075f8` was fetched and verified unchanged. This report is in progress; physical 2020 M1 acceptance remains blocked pending owner testing.

## Completed comparison before further changes

The unfinished Milestone 3.5.1 publication is now complete: [all 12 locations × 3 presets](validation/milestone351/final-native/comparison/COMPARISON.md), [raw measurements and native release evidence](validation/milestone351/final-native/README.md), and [continuous recording](recording/milestone351-full-journey.mp4). The exact baseline is `7df2f5abee54b8adcf27b8668263fba231a79033`.

Both revisions ran on the same hosted macOS ARM64 / Apple Paravirtual GPU, Godot 4.5.1 Vulkan, 960×540 windowed, V-sync/frame cap off. Both received identical benchmark/helper code, 60 entry frames, 120 settling frames and 600 steady frames per location. Two matrices per revision alternate order. Three startup processes per revision use separate initially empty application caches; OS/driver/filesystem caches are shared/warm and uncontrolled. This is not a physical-M1 or genuinely cold-OS result.

| Measure | Exact 7df2f5a baseline | cc50670 candidate |
|---|---:|---:|
| First source-project ready state, fresh app caches | 42.104 s | 25.999 s |
| Warm ready states | 29.651 / 31.441 s | 18.579 / 19.052 s |
| Medium Harlow worst entry | 1,866.183 ms | 65.718 ms |
| High Harlow worst entry | 2,393.057 ms | 89.192 ms |
| High Warehouse A worst entry | 143.454 ms | 168.372 ms |
| High Warehouse B steady p99 | 34.907 ms | 63.724 ms |
| High cab steady p99 | 35.804 ms | 26.649 ms |
| High passenger steady p99 | 29.956 ms | 28.943 ms |
| High near-fog worst steady frame | 108.670 ms | 80.467 ms |

The raw-derived CSV also includes median, p95/p99, worst, >33.3/50/100 ms counts, draw calls, texture/static memory and CPU callback intervals. Peak sampled RSS was 618.80 → 632.03 MiB. Source-to-menu time is not applicable: the game starts directly in the mission and has no startup menu. The existing probe measures mission readiness, not a fabricated menu milestone. GPU timestamps are unavailable (reported zero); render callback intervals include CPU work and waits and are not isolated GPU synchronization time. Separate native stack samples established fence waits in the old stall. The exact GPU workload behind every remaining outlier is not identified.

Startup phases show that warm preparation dominates the remaining delay: fog-proxy drawing takes 4.71–4.97 s, the platform 4.36–4.47 s, and Warehouse A 1.47–1.64 s; the remaining views each take roughly 30–52 ms. The cached shader code is reused, but pipeline creation still occurs in these early draws. Phase labels identify where work is observed, not a pure isolated cost of the named object: the current fog-proxy camera also sees the scene behind it. The next experiments will target that unnecessary work and missing preparation coverage, without changing fog difficulty or declaring readiness early.

The original fatal Vulkan timeout and later cache serialization/audio cleanup failures remain in the previous reports. CI success does not close that risk. Ten fresh-application-cache and ten warm launches plus repeated scene/preset/Continue/cancellation stress are still required for this milestone.

## Initial validation

All 300 existing tests passed unchanged on Linux in 140.5 seconds. The completed native run passed the same 300 tests in 161.8 seconds, five rendered regressions, journey 167, fuel recovery 35, fog failure 24, and process resume 17. ARM packaged/fresh launches passed 46 headless and 49 windowed checks; Intel fresh download passed 46 headless checks. The candidate and baseline failures are retained, including two baseline cache errors in the paired run.

Further optimization, extended stress, a fresh final build and final merge recommendation remain pending. No acceptance box is marked complete on the basis of a green workflow alone.
