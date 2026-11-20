# Native Milestone 3.5.2 evidence

Runtime source: `6038bfcd0f0c5427ae6c53435d2867282938f6e4`.
[Native run 44608806260](https://github.com/oiwdis/last-train-out/actions/runs/44608806260).
Godot 4.5.1, hosted macOS 26.7.2 ARM64 (3 logical CPUs), Apple Paravirtual GPU, Vulkan/MoltenVK 1.2.9.
These are not physical 2020 M1 results.

`startup.zip` and `renderer-stress.zip` retain the original artifacts unchanged.
The initial source-project startup probes reached readiness at 59.688, 20.019
and 15.774 seconds, with zero process errors or ObjectDB/resource-in-use warnings.
`initial-startup.csv` contains the measured stage boundaries and RSS;
`initial-preparation-phases.csv` contains every named preparation phase.
The first source launch remains well outside the cold-start target.

The six rendered lifecycle cases passed in 128.7 seconds: cancellation, fog
identity/gameplay invariants, rapid preset changes, original camera/material
preparation, idle HUD invalidation, and Continue with rider/cargo restoration.
The complete raw log still contains engine `Orphan StringName: servers` and
MoltenVK's informational 55 MB allocation-at-device-destruction message. These
are retained; the absence of game ObjectDB warnings does not establish a zero
GPU heap or explain the driver-level allocation report.

The superseded `f9ca998` evidence was moved intact to
[the intermediate folder](../intermediate-f9ca/README.md). It must not be mixed
with final-runtime startup or cleanup results.

MoltenVK 1.2.9 [source](https://github.com/KhronosGroup/MoltenVK/blob/v1.2.9/MoltenVK/MoltenVK/GPUObjects/MVKDevice.mm)
explains the allocation message's boundary: `MVKPhysicalDevice` samples
`getCurrentAllocatedSize()` **before** releasing its `MTLDevice`, then logs the
saved number. That function reads `MTLDevice.currentAllocatedSize` when available,
otherwise process memory. It is an informational pre-release snapshot, not an
ObjectDB game-object ownership report or a post-process leak measurement. This
explains why it cannot certify a zero heap; it does not prove that every reported
allocation is harmless or identify every driver-owned resource.

## Complete matched cohort, gameplay and export

The matched baseline is `7df2f5abee54b8adcf27b8668263fba231a79033`; the candidate
is `6038bfcd`. Both ran twice on the same machine at identical 960×540 settings,
600 steady / 60 entry / 120 settling frames per view. All twelve views and all
three presets remain included. [Full tables and CSVs](comparison/COMPARISON.md)
retain the slow candidate attempt, 389.657 ms fog outlier, all 11 candidate entry
frames over 100 ms, and both baseline `VK_INCOMPLETE` cache errors. Candidate
paired processes have no engine diagnostics. This does not establish good pacing.

The original test-log artifact SHA-256 is
`c9ba4e4443ee23312422583873c33c8a75754d362438c52fce031db2132cc048`.
`test-logs-without-movie.zip` preserves all 81 original paths except the MP4,
stored separately as `docs/recording/milestone352-full-journey.mp4`. Raw frame,
callback, pipeline, memory, loading, transition and failed baseline logs remain
unchanged. `build-selftest.zip` is the unchanged build-runner artifact;
`build-job.log` retains the complete CI console including bundle/ZIP validation.

Native tests: 304/304 in 100.4 s. The continuous headless and rendered journeys
both pass 167 checks, zero travel teleports, one legitimate Save/Continue
restoration. Fuel recovery 35, natural fog failure 24 and process resume 17 pass.
The new movie is 23:30.416667, 960×540 Medium, fixed offline 12 FPS, no cuts or
time acceleration. Capture timing does not establish real-time FPS or wall-clock
responsiveness. SHA-256:
`b8492b2ea4a2107ff16c821aa0fa40e81db78a86f001735d448e291a644c5aab`.
The beginning/scavenging and final escaped-results frames were also inspected.

## Development ZIP and fresh-download failure

[LastTrainOut-macos-universal.zip](https://github.com/oiwdis/last-train-out/actions/runs/44608806260/artifacts/14576722679)
contains only the root `Last Train Out.app`, with executable permissions and
both arm64/x86_64 Mach-O slices. Independent CRC, byte size, SHA and tree identity
are in `release-integrity.json`. Size 292,540,491 bytes; SHA-256:
`e1cff244b9edf7a8af1b6371ad311a4cf0fafa79301beb3ecaec2517ae837159`.
Build 70, ad-hoc signed, **not notarized**; Godot is included.
The CI merge commit `698a5e436ae4ec6001cd2edd7201b03cd9292e15` has the exact same
file tree as runtime source `6038bfcd`; both tree hashes were independently checked.

This is **not an accepted release**. Build-runner ARM launch passed 46 headless
and 49 windowed checks. Fresh Intel passed 46 headless checks (`intel-selftest.zip`,
`intel-job.log`); Intel GPU rendering was not tested. Fresh ARM passed 46 headless
checks but then **lost its Vulkan device** during the windowed preset sequence.
The complete `arm64-selftest-failed.zip` and `arm64-failed-job.log` are retained.
The failed windowed process has no completed JSON and exits 133 / SIGTRAP, with
Metal command-buffer timeouts, failed Vulkan fence wait and device loss.
`VK_EXT_device_fault` is unavailable. Its readiness was 77.061 seconds; the
last printed warmup has 112 draw pipelines. The following packaged 81-case
benchmark was skipped. No retry replaces this failure, and the earlier successful
build-runner launch cannot make this fresh check pass.

## Completed exported Vulkan stress — failed stability acceptance

[All 31 attempts](stress/STRESS.md) and `stress/every-attempt.csv` include every
scheduled outcome. `release-stress.zip` preserves all 68 original paths unchanged,
including two native `.ips` crash reports; `release-stress-job.log` is the full
CI console. Artifact SHA-256:
`361c4c3e8090c637f6e6defb432cf7846dc20709004ae677ff9c4ce139e55b41`.
Pack SHA-256:
`7950f615a9ec2a91e0a3e2ba0fd71b76732a4d8b1b5346a663494b8acd656703`.

The complete series takes 1,193.033 seconds, with no timeout or skipped attempt:
29 processes succeed, cold 3 and cold 6 lose the Vulkan device before readiness.
Both failures use High, exit with SIGTRAP (-5), and preserve Metal timeout/fence
failure logs plus crash stacks through `command_queue_execute_and_present`.
The failed attempts have no final ready-state JSON; that absence remains a
failure, not a zero-second startup. All ten warm launches pass, as do three
35-check Save/Continue/preset/fog/restart processes, three 3-check early exits,
and four complete 72-row short matrices (including the explicit warm seed).
The separate fresh ARM windowed self-test also lost the device. These three final
candidate losses on two runners prevent a stability acceptance claim.

Successful cold readiness: 21.875–89.107 s (eight successes, two crashes).
Warm readiness: 16.466–20.564 s (ten successes). Peak sampled RSS: 585.875 MiB.
The three post-seed station matrices retain a 236.544 ms entry and 259.204 ms
steady outlier. Their 24-sample/8-settling-frame windows are short stability
fixtures; the full matched 600-sample cohort remains the performance comparison.
Private application caches isolate these tests from the normal player save;
baked shaders and OS/driver caches remain shared. Native audio self-test and
Dummy-audio stress are distinguished; neither successful fixture overrides a
failed one.

All 29 successful exported stress processes have zero ObjectDB/resource-in-use
warnings. `stress/cleanup-diagnostics.csv` retains all exits, the engine StringName
and MoltenVK pre-Metal-release allocation snapshots. Three lifecycle processes
end at 46 / 45 / 45 MiB; this is not a post-exit GPU leak measurement. Failed
processes do not count as cleanup passes.

All ten cold processes start with a logged 0.0 MiB PSO cache. The explicit seed
saves 15.3 MiB; all ten warm launches load it. The first lifecycle process expands
it to 15.7 MiB, reused afterward. CSV cache-directory inventory describes
`user://shader_cache`, not the separate PSO storage; raw engine cache events are
retained in `stress.json` and each process log.
