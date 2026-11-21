# Replicating the first fog camera comparison

Two additional hosted Macs ran the signed build 111 pack on the stock Vulkan executable at 960 × 540. The same diagnostic launched High with a fresh writable game cache 32 times per host. It alternated just the first camera position and reversed the initial order on the second host. Preparation included the full scenery, fog material, uncovered platform and all subsequent camera views. The OS and driver caches are shared within a host. [Workflow](https://github.com/oiwdis/last-train-out/actions/runs/44869970951)

| Cold High launches | World-origin first, device losses / starts | Platform first, device losses / starts |
|---|---:|---:|
| Forward host | 2 / 16 | 0 / 16 |
| Reverse host | 9 / 16 | 0 / 16 |
| Both hosts | 11 / 32 | 0 / 32 |

| Host, camera | Fog proxy, median seconds | Following platform, median seconds | Specializations added, fog / platform |
|---|---:|---:|---:|
| Forward, origin | 3.19 | 2.00 | 41 / 41 |
| Forward, platform | 4.93 | 0.16 | 82 / 0 |
| Reverse, origin | 3.99 | 2.56 | 41 / 41 |
| Reverse, platform | 6.15 | 0.23 | 82 / 0 |

The table counts recorded phase completions, including those reached by an application that subsequently exited. The device can report a queued command-buffer timeout after the CPU records a later phase. These traces identify which preparation work moved and how often the app lost its device in this experiment. They cannot identify the individual GPU command responsible. The normal build 117 release gate runs the exported player through its own full launch and lifecycle series. [Counts, failures and crash symbols](camera-pair.json) · [Raw phase counters and timings](preparation-phases.csv) · [All forward process logs](vulkan-camera-pair-forward.zip) · [All reverse process logs](vulkan-camera-pair-reverse.zip)

Ten of the eleven failed processes last recorded the uncovered platform and one last recorded the fog proxy. Among successful starts, median engine time to play was 18.00 / 18.10 s (origin / platform) on the first host and 21.14 / 23.10 s on the second. The longest initial gameplay frame with the platform camera was 285.68 ms. On the other host the original camera recorded a 617.56 ms initial gameplay frame. [Startup and first 30 playable frames](STARTUP.md)
