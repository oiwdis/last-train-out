# Build 93 source-only control

This universal build includes the corrected native sampler, source shader inventory and worker shutdown correction. It predates delivery of the offline Metal libraries. The two renderers used the same game pack. [Build and ZIP hashes](../build-93.json) · [Independent ZIP validation](../build-93-zip.log) · [Original workflow and downloads](https://github.com/oiwdis/last-train-out/actions/runs/44798649173)

| Hosted result | Native Metal | Vulkan |
|---|---:|---:|
| Clean stress processes | 95/95 | 94/95 |
| Device losses in stress | 0 | 1, cold Low |
| Steady median / p99 | 6.173 / 14.264 ms | 8.641 / 20.767 ms |
| Worst timed entry | 524.371 ms, Low cab | 146.096 ms, Low Warehouse A |
| Worst steady interval | 658.220 ms, Low passenger car | 127.357 ms, Medium approaching fog |
| Separate fresh Apple Silicon window | Both normal starts and all 49 native-audio checks passed | Device loss after physical cargo release. Exit 133 |

The fresh native High player reached play in 105.046 s cold and 29.365 s warm. Its worst loading UI gaps were 1,081.816 and 165.735 ms. Across the stress schedule, 36/40 cold native processes met 30 s and 13/40 warm processes met 15 s using the selector clock. In the Vulkan fresh window, MoltenVK reported command-buffer timeouts on both submit and presentation, followed by Godot's fence wait and device-lost report. The build-host window and all 20 stress cold High processes completed. The failed fresh process remains an independent result. [Fresh native reports](raw/selftest-arm64-metal.zip) · [Fresh Vulkan app logs](raw/selftest-arm64.zip) · [Vulkan job output](fresh-vulkan-job.zip)

[All 36 paired views](matched/README.md) · [All original frame arrays](raw/metal-drivers.zip) · [Native stress by scenario](metal-stress/STRESS.md) · [Vulkan stress by scenario](vulkan-stress/STRESS.md) · [Startup cohort clocks and thresholds](startup-cohorts.csv) · [Journey checks and save](raw/metal-journey-diagnostics.zip)
