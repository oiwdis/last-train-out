# Native integration evidence: build 46

[Workflow run 44460966340](https://github.com/oiwdis/last-train-out/actions/runs/44460966340) uses source `45c3b338a694f587b5290af0e8ce19208d0a702e`; GitHub's pull-request merge checkout is `d09ebfc90352ff840b5ab8ea66e34806bd3da158`. Some raw reports identify that merge checkout. Both correspond to the same tested integration runtime. The later documentation/evidence commit only publishes these files.

The build job passed every required stage: asset checks, import validation/main-scene smoke check, **292 automated tests**, source-identity preservation, gameplay scenarios, export and bundle/ZIP checks, packaged headless/windowed checks, performance comparisons and full recording. `results.json` and `tests.log` retain the full suite. All **274 distinct source tests** remain; 18 new integration regressions bring the count to 292.

- `continuous-journey.json`: 167 passing checks, all three stations, 4,260.006 m, 1,392.8 simulation seconds, escaped, zero travel teleports and one save restoration.
- `fuel-shortage-gameplay.json`: 35 passing fuel exhaustion/recovery checks.
- `stranded-gameplay.json`: 24 passing natural fog-death checks.
- `process-resume.json`: 17 passing cold second-process save/load checks.
- `build/`: exported ARM headless 46/46 and windowed 49/49, plus export/material inventory logs.
- `arm64/`: first fresh-download attempt, headless 46/46 and windowed 49/49. The subsequent packaged legacy benchmark **failed** with Vulkan device loss during High preparation; `packaged-benchmark-presets.log` retains the complete failure. This attempt's job is not claimed as passing.
- `arm64-retry/`: attempt 2 downloads the **same ZIP hash** on a fresh hosted runner. Headless 46/46, windowed 49/49 and all 81 packaged diagnostic cases pass (6 preset, 3 route and 72 entry/steady matrix rows). The complete workflow is green on attempt 2. A successful retry does not establish the cause or a fix for the first device loss; both attempts remain visible.
- `intel/`: fresh-download x86_64 headless 46/46. The hosted Intel runner has no usable display GPU, so it does not validate Intel rendering.

## Application download

[LastTrainOut-macos-universal.zip](https://github.com/oiwdis/last-train-out/actions/runs/44460966340/artifacts/14501384087) contains `Last Train Out.app`; no separate Godot installation is needed. The ZIP has **292,523,782 bytes** and SHA-256 **`69b0ca231a9508b039015901218514d4cc305b07aa769d3e1149f1d7c65d47d3`**. Both `lipo` architectures, embedded resources, ad-hoc signature, every ZIP entry and re-extracted bundle are checked by CI. GitHub sign-in is needed; the app artifact is retained for 30 days. Optional signing/notarization was not requested and was skipped. This app is **not notarized**.

## Continuous recording and screenshots

[Full video](../../../recording/milestone35-full-journey.mp4): **23:24**, 960×540, 12 FPS, 16,848 frames, 32,997,692 bytes, H.264/AAC. SHA-256 **`ebd3b67de46b1dd91624f15cbe91ab6b281ea5a9373cd340a80312e7afb118fc`**. Downloaded bytes match `visual/media.json`. The full stream decodes successfully; sampled frames at 00:25, 21:40 and 23:21 show real scavenging, post-resume departure and escaped results.

`visual/continuous-journey.json` and `visual/full-journey.log` contain all 167 passing controls/collision checks for the recorded journey, zero travel teleports, one legitimate save restoration and 1,393.6 simulation seconds. The actual Save/Continue buttons reload at Blackwater in the same recording. There are no edits, location cuts or playback-speed changes. Scripted inputs use the real movement, interaction, collisions, train and fog simulation. Fixed-rate Movie Maker output is **not a real-time FPS measurement**.

`visual/` contains 14 captured journey frames and the actual played save. `performance/screenshots/` contains all twelve locations in each preset. Those 36 images use explicitly positioned rendering fixtures; their HUD state does not prove mission progression. See the [annotated gallery](../../../MILESTONE35_GALLERY.md) for the distinction and visible limitations.

## Performance and hardware scope

`performance/` retains all raw entry and steady frame intervals, CPU/render counters, pipeline deltas, external RSS samples, comparison CSVs and the plot generator. The cohort uses macOS 26.7.2, three virtual CPUs, **Apple M1 (Virtual) / Apple Paravirtual GPU**, 960×540 windowed, Godot 4.5.1. Integration and exact PR #4 use Vulkan/MoltenVK; exact PR #5 uses Metal. GPU timings are unavailable. These are cache-conditioned rendering fixtures, not physical M1 acceptance or the full gameplay CPU workload.

The [performance report](../../../PERFORMANCE_MILESTONE35.md) explicitly retains a 2.51-second entry frame, a 0.94-second near-fog steady outlier, long startup and observed source regressions. [Physical 2020 M1 fullscreen instructions](../../../M1_MILESTONE35.md) are provided; that device was unavailable here.

Packaged diagnostic checks use just 24 samples after 8 warm frames to validate availability and execution. They do not replace the full cohort's 600 steady samples, 120-frame warmup and 60 entry samples. CSV files use repository-standard LF line endings; their numerical contents and the raw JSON samples are unchanged.

Earlier [run 44](../native-run44/) and [run 45](../native-run45/) failures remain published. Passing later checks do not erase those failures or establish eliminated stutter. The source branches remain unchanged and the integration PR remains a draft.
