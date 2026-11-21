# Medium frame times in the warehouses and train

The comparison below uses the same PR #6 pack on two hosted Macs. Each ran both packs at 960 × 540 on native Metal. The location, camera, target, fog position, preset and 180-frame sample length match across all four timing passes. Each host measured the integration first, the overhaul twice, and the integration again. Each individual process supplied 2,880 steady Medium frames across all 16 views. Builds 117 and 118 used the same world geometry and native executable. The intervening game change scoped a macOS Vulkan preparation camera.

| Hosted run and location | Integration first / repeat p95 (ms) | Overhaul first / repeat p95 (ms) |
|---|---:|---:|
| 117 · All 16 views | 17.60 / 12.88 | 11.78 / 12.02 |
| 117 · Warehouse B | 15.94 / 9.34 | 11.33 / 7.69 |
| 117 · Locomotive cab | 19.20 / 14.68 | 12.76 / 15.42 |
| 117 · Passenger car | 25.62 / 16.56 | 15.19 / 19.37 |
| 117 · Inside dangerous fog | 13.99 / 11.35 | 8.82 / 8.79 |
| 118 · All 16 views | 13.30 / 16.17 | 17.12 / 17.45 |
| 118 · Warehouse B | 12.71 / 12.27 | 19.44 / 13.78 |
| 118 · Locomotive cab | 13.15 / 16.56 | 17.61 / 18.55 |
| 118 · Passenger car | 16.54 / 18.20 | 18.89 / 28.20 |
| 118 · Inside dangerous fog | 11.68 / 17.83 | 14.56 / 13.11 |

On the 118 host, 339 of 5,760 candidate steady frames exceeded a 16.67 ms refresh interval and 22 exceeded 33.3 ms. The integration counts were 166 and 11. The direction reversed on the 117 host, with 33 and one for the candidate and 223 and 17 for the integration. The Harlow first-frame delays at preset handoff are measured separately. [All steady samples and budget counts](medium-interiors.csv) · [Entry-frame sequences](PRESET_ENTRY.md)

On the 118 passenger repeat, the slowest 5% of frames averaged 39.04 ms between render callbacks, 0.60 ms in gameplay processing and 0.16 ms in physics. This view submitted about 1,124 draws and 1.58 million primitives per frame against 1,109 and 1.59 million in the reference. Warehouse B submitted 475 draws and 746,006 primitives against 460 and 750,948. No draw, surface or specialization pipeline additions were recorded during these steady windows. The standard native library-policy matrix on a separate host measured passenger p95 at 13.62 ms with immediate library preparation and 10.77 ms with lazy preparation. Both used the same build 118 pack, a different 12-location schedule and 60 warm-up frames. GPU timestamps were unavailable. The measured delay falls mostly between render callbacks. Driver waiting and GPU execution could not be separated.

## Which exterior meshes reach these cameras

The packaged build 118 data was also loaded in pinned Godot 4.5.1 on Linux llvmpipe Vulkan at 320 × 180. Each fixed camera ran with normal art, then with one named group hidden per measurement, and again with all art restored. Each step settled for eight frames and recorded 24. The order of the three groups was reversed for the cab. Only the visual nodes were toggled. Collision, the train and the original door openings stayed present. The table gives mean submitted draw calls. The archive includes every local software frame interval, camera transform, shape count and unedited log.

| Camera | Full before | Corridor hidden | Harlow main line hidden | Inner brick leaves hidden | Full after |
|---|---:|---:|---:|---:|
| Warehouse B | 478.0 | 459.0 | 467.0 | 477.0 | 478.0 |
| Locomotive cab | 1001.9 | 980.0 | 988.0 | 999.0 | 997.0 |
| Passenger car | 1115.0 | 1100.0 | 1104.0 | 1113.0 | 1115.0 |

At the passenger camera, hiding the entire route corridor removed 15 of 1,115 draws and 5,076 of 1,504,879 submitted primitives. Hiding the Harlow main line removed 11 draws and the repaired warehouse leaves removed two. The two full passenger measurements returned exactly the same draw and primitive counts. At the cab, full draws varied by about five across the sequence, so smaller differences there have similar uncertainty. The local timings reflect the software device.

The fixed-view comparison documents a steady Medium regression on the latest hosted run, most clearly in the passenger car. The quantified mesh changes and engine counters establish how much work was submitted. The widely differing results across processes leave the magnitude on the owner’s physical M1 open. [Fixed-view raw frames](raw-environment.zip) · [Original build 117 results](build-117/README.md) · [Independent native library runs](raw-release-checks.zip) · [Software geometry controls, fixture and raw output](medium-interiors-local.zip)
