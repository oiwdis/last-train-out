# Experimental exported stress — mobile-vulkan

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 11.891 / 12.812 / 12.935 / 12.935 | 44.608 | — / — |
| cold medium | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 12.038 / 12.441 / 20.597 / 20.597 | 76.196 | — / — |
| cold low | 4 | 4 | 3 | 3 | 0 | 1 | 0 | 12.076 / 12.355 / 16.772 / 16.772 | 43.705 | — / — |
| warm high | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 13.410 / 14.139 / 15.096 / 15.096 | 73.491 | — / — |
| warm medium | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 12.008 / 14.040 / 14.833 / 14.833 | 64.695 | — / — |
| warm low | 4 | 4 | 4 | 4 | 0 | 0 | 0 | 10.195 / 12.636 / 14.664 / 14.664 | 60.809 | — / — |
| isolation-preflight | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 2.095 / 2.095 / 2.095 / 2.095 | 49.829 | — / — |
| warm-seed-matrix | 1 | 1 | 1 | 1 | 0 | 0 | 0 | — | — | 629.550 / 55.828 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 724.555 / 64.169 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
