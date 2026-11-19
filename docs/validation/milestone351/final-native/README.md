# Completed native Milestone 3.5.1 validation

[Run 44583413439](https://github.com/oiwdis/last-train-out/actions/runs/44583413439) succeeded: source `cc50670c9ae70aa2de7ce92185a229d284c075f8`, CI merge tree `5fe2546129c4cf6d39b0518097565556e8d0cc3b` (identical files), Godot 4.5.1, hosted Apple Paravirtual GPU on macOS ARM64. This is not physical M1 acceptance.

- All 300 native tests passed in 161.8 seconds, preserving all original 292 identities.
- Five Vulkan lifecycle regressions passed, including rider/cargo restoration during preparation.
- Continuous controls-driven journey 167/167, fuel recovery 35/35, natural fog death 24/24 and separate-process resume 17/17 passed.
- Universal export, baked shader inventory, bundle/ZIP integrity and ad-hoc signature checks passed.
- Exported ARM app passed 46 headless and 49 windowed checks. Fresh-download ARM passed the same checks and 81 packaged diagnostic cases. Fresh-download Intel passed 46 headless checks; Intel GPU rendering is not available on that runner.
- Every candidate startup/matrix and packaged diagnostic exited without ObjectDB/resource-in-use errors. The verbose engine-level `servers` StringName remains. Historical fatal Vulkan device loss is not claimed fixed.

[Full paired comparison](comparison/COMPARISON.md) includes all twelve locations and three presets, raw-derived distributions, preparation times, memory and all unfavorable results. `test-logs-without-movie.zip` preserves every file in the original test-log artifact except the MP4, stored separately as `docs/recording/milestone351-full-journey.mp4`. The original artifact SHA-256 is `0f8e6c557fb248dda110d4e3e3ad59c775651f758231c0b561d3d3bee3d77c57`. Other ZIPs retain the original native artifacts unchanged.

The continuous movie is **23:28.17**, 960×540 Medium, 12 FPS offline Movie Maker capture, no cuts or time acceleration. The 167-check driver uses normal movement/interactions and actual Save/Continue: zero travel teleports, one save restoration. Its capture rate is not measured real-time FPS. Movie SHA-256: `88c5765da0c9ba8f8910b4df251617ecf27af1c47d07f648c76937ef50fb6621`.

[LastTrainOut-macos-universal.zip](https://github.com/oiwdis/last-train-out/actions/runs/44583413439/artifacts/14564792174) contains `Last Train Out.app`, including Godot. SHA-256: `d4decb3faf11b6cbcdbbe2f1256437282c4f0f961e14e05839be30d0ce07bae7`. Ad-hoc signed, **not notarized**.

Performance remains an acceptance concern: warm readiness 18.579/19.052 seconds, High Warehouse A entry 168.372 ms, and several steady-state regressions. This successful workflow is not merge approval.
