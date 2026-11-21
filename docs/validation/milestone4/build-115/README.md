# Intermediate build 115

Build 115 at `0744be1d81b34511e15d9e21a5f1d9cc3ced3f86` contains the native Metal vertex-format locking correction. Its Ashford apron and initial High Vulkan camera match build 111. The subsequent game build addresses those two issues. [Development ZIP](https://github.com/oiwdis/last-train-out/actions/runs/44865620992/artifacts/14693425752) · [File and pack checksums](development-build.json) · [All CI jobs and artifacts](workflow.json)

| Check | Result |
|---|---|
| Linux and macOS tests | 310/310 and 310/310, including all 305 original identifiers |
| Native Metal launch and lifetime stress | 95/95 clean. 0 processes failed |
| Default Vulkan launch and lifetime stress | 83/95 clean. 12 processes lost the device |
| Matched hosted timings in ms, PR #6 / build 115 | Medium median 6.65 / 5.66, p95 10.85 / 8.79, p99 15.08 / 11.51, worst entry 176.44 / 665.57 |
| Ordinary hosted Metal High player | 39.00 s cold, 35.18 s warm. 0 source compiles on the compatible profile |
| Packaged native Metal journey | 167 passing checks, 4,260.006 m, one Save/Continue and zero travel teleports |

The same-pack native High experiment completed 36/36 processes with the old executable and 36/36 with the corrected one, including 17 cold and 17 warm High starts per executable. The known build 111 crash was intermittent. [Original crash and analysis](../build-111-native-high/README.md) · [Two native runtime cohorts](native-high-workers.json) · [Every process and log](native-high-pipeline-workers.zip)

[Tests and mission outcomes](gameplay-results.json) · [Actual build 103 to 115 save check](../save-103-to-115.zip) · [Per-location frame times and draw counts](locations.csv) · [Timed scenes, all raw intervals and startup logs](raw-environment.zip) · [All 114 native pictures](https://github.com/oiwdis/last-train-out/actions/runs/44865620992/artifacts/14694682031) · [Full movie](https://github.com/oiwdis/last-train-out/actions/runs/44865620992/artifacts/14695281565) · [Journey events and film receipt](recorded-journey.zip)

[Every stress result](renderer-stress.json) · [Default Vulkan High including failures](release-stress-high.zip) · [Default Vulkan mixed series](release-stress-mixed.zip) · [Native Metal mixed series](metal-stress-mixed.zip) · [Raw launch, cleanup and rendering logs](raw-release-checks.zip) · [Compiled shader profile and native traces](world-stage-preparation.zip)

The 665.57 ms Medium platform redraw occurred in the second of two matched passes. The corresponding first pass took 6.19 ms. The ordinary Medium launcher’s first 30 frames peaked at 18.09 ms cold and 18.44 ms warm. [Frame brackets and prior pipeline changes](MEDIUM_ENTRY.md)
