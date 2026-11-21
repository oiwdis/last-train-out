# Build 117 and runtime preset changes

The first-camera experiment covered cold High launches. Build 117 also used the platform camera every time a running macOS Vulkan process prepared High. The build host recorded two separate MoltenVK device losses while changing presets. The official Godot 4.5.1 source lifecycle test passed the camera-policy and scene-exit tests, then failed during the first fog-state preset sweep. The exported default player separately passed carrying, camera and cargo release checks, completed the Low and Medium preparation draws and died during the High preparation. Both logs contain Metal command-buffer timeouts and Vulkan device loss. The reported CPU markers and older completed preparation counts locate the sequence. The host exposes no faulting GPU command.

The corresponding tests passed on builds 108, 111 and 115. Build 117’s 312/312 automated tests passed on Linux and macOS, including all 305 original identifiers. Those headless results do not exercise the failed windowed driver path. The fallback stock-binary Metal probe completed 49 checks. Its diagnostic success leaves the original default-window failure in place. [Source lifecycle log](renderer-stress.zip) · [Exported window, headless, and fallback logs](selftest-build.zip) · [Normal suite and route checks](gameplay-results.json) · [Build workflow](https://github.com/oiwdis/last-train-out/actions/runs/44869971053)

The revised policy confines the platform camera on macOS Vulkan to a High first preparation in a fresh process. Later preparations use the historical origin through preset changes and scene reloads. Native Metal continues to use the platform at all presets and retains its existing origin control. Both camera locations now have a phase marker. The full fog, switching, cancellation, Continue and rider-and-cargo tests still run. [Cold-camera replication](../vulkan-world/replication/README.md)

A fresh download on a second hosted Apple Silicon Mac passed its default headless check, then lost the Vulkan device in the windowed test after the cargo checks during the Low → Medium → High preset sweep. Its log ended before reporting a completed preset sweep. This gives three observed failing stock processes on two Macs. [Fresh Apple Silicon download evidence](selftest-arm64.zip)

The first Harlow redraw after the Low dangerous-fog view and a switch to Medium took 12.77 ms on the first timed pass and 899.67 ms on the repeat. The same integration game on the same runner took 10.83 and 676.88 ms. The separate native capture pass ended its preceding preset at the Blackwater road and measured 4.33 ms. Five native standard or library-policy matrices ending at mission results measured 1.84–2.56 ms on the first Medium redraw. The different prior camera, HUD, readbacks and host/cache conditions prevent a single-factor attribution. [Raw first frames and counters for all sequences](native-preset-sequences.csv)

## Complete release results

The candidate also completed its independent route, image and launch schedules. All processes are included in the archive. [Complete release status and individual jobs](workflow.json) · [Universal game](https://github.com/oiwdis/last-train-out/actions/runs/44869971053/artifacts/14695813361) · [Independent package receipt](development-build.json)

| Check | Result |
|---|---|
| Gameplay | 312/312 on both operating systems, including all 305 original tests |
| Uncut native Metal journey | 167/167 checks, 4,260.006 m, one Save/Continue and zero travel teleports. 16,930 frames at 12 FPS offline |
| Native Metal release processes | 95/95 clean, 0 device losses |
| Default Vulkan release processes | 91/95 clean, 4 device losses |
| Hosted matched Medium steady p95 | 15.44 ms on the integration, 11.87 ms on build 117 |
| Hosted matched worst Medium entry | 676.88 ms on the integration, 899.67 ms on build 117 |
| Fresh native High player | 34.01 s cold and 27.34 s warm, 0 compatible-profile source compilations |

[All per-location measurements](locations.csv) · [Raw frame intervals and launch logs](raw-environment.zip) · [All 114 native images](https://github.com/oiwdis/last-train-out/actions/runs/44869971053/artifacts/14697079649) · [Journey recording](https://github.com/oiwdis/last-train-out/actions/runs/44869971053/artifacts/14696137752) · [Gameplay outcomes](gameplay-results.json) · [Movie audit](movie-motion.json) · [Exact moving build 103 checkpoint](../save-103-to-117.zip)

[Launch stress with every failed process](renderer-stress.json) · [Rendered lifecycle and two exported windows](lifecycle-results.json) · [First fog cameras](first-fog-camera.json) · [Full logs and crashes](raw-release-checks.zip) · [Matched native worker comparison](native-high-workers.json)

The separate stock Godot source benchmark also failed its final gate. Compared with commit `7df2f5abee54b8adcf27b8668263fba231a79033`, the candidate completed both 12-location timing passes but lost Vulkan in one of three Low starts. The reference lost Vulkan in two Low starts and one timing pass, and two surviving reference processes reported a cache-write diagnostic. The separate source film completed. In the 95-process default release stress, the four failures were one warm High launch and all three preset/fog/Continue cycles in the mixed suite. All 20 cold High release starts completed. [All ten source comparison processes, phases and diagnostics](stock-source-comparison.json) · [Full source timing and failed logs](stock-source-comparison.zip) · [Mixed release/lifetime checks](lifecycle-results.json)
