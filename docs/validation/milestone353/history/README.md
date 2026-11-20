# Three revisions on one hosted Mac

The experiment used Godot 4.5.1, 960×540, windowed Forward+/Vulkan, Apple Paravirtual GPU and the same benchmark scripts and imported texture bytes. Scene imports were rebuilt per repository revision. Each revision ran three cold High launches in rotated order, one cold matrix in revision order and one warm matrix in reverse revision order. Each matrix measured 60 entry and 180 steady frames per location and preset, with 60 settling frames. OS and driver caches were shared. The first process on the runner was the original revision.

| Measure | 7df2f5a | cc50670 | 6038bfc |
|---|---:|---:|---:|
| Cold High launches completed | 3/3 | 3/3 | 3/3 |
| Cold High ready, individual seconds | 51.992 / 25.880 / 24.488 | 20.449 / 21.446 / 20.280 | 20.339 / 20.856 / 20.177 |
| High Harlow entry worst, ms | 2,523.112 | 105.452 | 67.328 |
| Medium Harlow entry worst, ms | 1,048.701 | 47.101 | 46.979 |
| High Warehouse B steady p99, ms | 28.000 | 23.937 | 29.013 |
| High cab steady p99, ms | 29.505 | 19.076 | 23.048 |
| High passenger car steady p99, ms | 24.089 | 23.507 | 24.745 |
| Medium dangerous fog steady worst, ms | 34.741 | 17.704 | 22.386 |

All six matrices completed. The original revision reported nonfatal pipeline-cache serialization errors on every process. No device loss surfaced in these 15 processes. Other retained experiments include actual device losses before 3.5.1 and repeatedly at 6038bfc. These data cannot identify a first revision with a given crash probability.

Harlow's reduction predates cc50670. The 3.5.1 change to draw across the frame queue before exposing the play camera is retained. Warehouse B slowed between cc50670 and 6038bfc in this cohort and in the previous comparison against the original revision. The absolute p99 changed across hosts. The 389.66 ms dangerous-fog frame from the longer 3.5.2 cohort did not recur on any revision here. Each short steady cell contains only 360 frames. The later comparison uses 1,200 per cell. No commit that uniquely causes the fog outlier is established.

High Warehouse B issued exactly 653 draws and 1,007,915 primitives with 377,754,560 texture bytes on every revision in both passes. Its per-process p99 was 15.526/30.689 ms on the original, 14.706/26.286 on cc50670 and 15.931/38.252 on 6038bfc. Every revision slowed in the second pass, despite reversed revision order. Render-server CPU timing for 6038bfc rose from 0.915 to 1.643 ms across the two runs. Medium dangerous fog held 349 draws and 319,418,864 texture bytes across all six runs. The second-pass outliers and unavailable GPU timestamps limit attribution to any of the three newly prepared interiors.

[Every process and its diagnostics](attempts.csv) · [Each measured view, CPU time, texture memory, calls and primitives](frames.csv) · [Pooled frame distributions](pooled.csv) · [Preparation phases](phases.csv) · [Raw intervals, timelines and logs](history-native.zip) · [Hosted job](https://github.com/oiwdis/last-train-out/actions/runs/44673670898/job/136080297658)
