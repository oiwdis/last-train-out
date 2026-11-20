# Experimental exported stress — forward-metal

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 16.315 / 18.922 / 22.190 / 23.242 | 103.792 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.808 / 21.154 / 27.988 / 27.988 | 118.456 | — / — |
| cold low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.487 / 19.692 / 35.921 / 35.921 | 71.119 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 14.791 / 17.903 / 20.982 / 21.416 | 91.14 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.996 / 17.535 / 20.954 / 20.954 | 67.707 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 14.918 / 16.326 / 19.979 / 19.979 | 118.779 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 1.627 / 1.772 / 2.987 / 2.987 | 61.994 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 322.890 / 424.511 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 129.453 / 42.282 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
