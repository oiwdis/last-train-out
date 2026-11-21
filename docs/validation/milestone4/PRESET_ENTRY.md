# First Harlow redraw after a graphics change

Each measurement starts at the first native Metal redraw of the same Harlow platform camera. The paired world timing run reaches this pose immediately after the old preset’s last dangerous-fog view, a real preset change, and the fixture’s return from fog to clear daylight. The capture run visits three more locations, hides most UI, reads back screenshots and ends the old preset at the Blackwater level crossing. The independent standard and library-policy matrices end at the mission results screen and have their own processes and hosted GPUs. These are different camera and workload sequences.

| Build | Preset | PR #6 world, first / repeat (ms) | Candidate world, first / repeat (ms) | Candidate capture (ms) | Standard and library matrix first redrawn frame, range across five processes (ms) |
|---|---|---:|---:|---:|---:|
| 111 | Medium | 10.63 / 4.48 | 7.10 / 9.52 | 1.71 | 2.25–8.34 |
| 111 | High | 12.20 / 288.90 | 97.21 / 247.94 | 2.23 | 3.80–8.04 |
| 115 | Medium | 19.28 / 50.42 | 6.19 / 665.57 | 2.91 | 2.26–6.69 |
| 115 | High | 764.62 / 10.48 | 602.05 / 439.26 | 4.97 | 3.62–5.39 |
| 117 | Medium | 10.83 / 676.88 | 12.77 / 899.67 | 4.33 | 1.84–2.56 |
| 117 | High | 696.56 / 694.38 | 957.33 / 651.89 | 2.91 | 2.00–2.88 |
| 118 | Medium | 691.29 / 18.34 | 833.39 / 802.68 | 8.19 | 2.44–4.56 |
| 118 | High | 1183.45 / 819.01 | 278.65 / 28.04 | 6.02 | 3.41–6.72 |

On the current build 118 pair, both Medium redraws exceeded 800 ms immediately after the grouped graphics and camera change. The corresponding ordinary Medium launches peaked at 19.15 ms cold and 19.12 ms warm across their first 30 playable frames. A separate 118 capture with a different preceding view took 8.19 ms, and the five independent matrices ranged from 2.44 to 4.56 ms. Both slow draws remain in the published distributions.

The 899.67 ms build 117 Medium redraw had 899.15 ms between the render callbacks, 0.24 ms in gameplay processing and 0.49 ms in physics. The next frame took 12.18 ms. The first pass on the same Mac took 12.77 ms. Both added eight draw pipelines and 15 specializations between preset readiness and the new camera, and zero more during the measured window. Direct ordinary Medium launches recorded first-30-frame maxima of 30.98 ms cold and 31.84 ms warm. The same matched integration build also had a 676.88 ms Medium redraw on that host.

The timing isolates a recurring rendering delay at the combined preset, fog, and camera change. The comparison does not isolate UI visibility, fog blending, application/driver caches, queue synchronization or host contention individually. No individual GPU command timing was available. The affected frames remain in every percentile and worst case. The owner’s physical Medium performance is still an open check.

[Every compared first frame, counters, render brackets and source report names](native-preset-sequences.csv) · [Full current timing matrix](FRAME_TIMES.md) · [Current first 30 direct-launch frames and raw timing logs](raw-environment.zip) · [Current independent stress and library-policy logs](raw-release-checks.zip) · [Build 115 first Medium redraw](build-115/MEDIUM_ENTRY.md) · [Build 117 source evidence](build-117/README.md)
