# Independent rebuild and matched performance confirmation

The normal branch workflow rebuilt the same shipped source at 0697621649a1493b2a341343d3da7a3b987ff9ab as universal development build 77. It reran the 95-process default Vulkan stress and the alternating two-pass comparison against 7df2f5a. Each source revision contributed 43,200 steady and 4,320 entry frames. Conditions and sampling were the same as the primary build-73 comparison, on a different hosted ARM runner. Retain the two comparisons independently.

| Measure | Original on confirmation runner | Candidate on confirmation runner |
|---|---:|---:|
| Low mission-ready times, s | 101.063 / 32.971 / 30.607 | 28.606 / 23.700 / 21.591 |
| High Harlow worst entry, ms | 2,510.907 | 81.929 |
| High Warehouse B p99, ms | 19.365 | 19.470 |
| High locomotive cab p99, ms | 19.940 | 18.210 |
| High passenger car p99, ms | 20.593 | 20.301 |
| Medium dangerous fog worst steady, ms | 31.533 | 42.277 |
| Medium mission results worst steady, ms | 18.293 | 44.373 |
| Low Warehouse B worst steady, ms | 25.350 | 976.263 |
| Entry frames over 100 ms | 11 | 6 |
| Steady frames over 100 ms | 3 | 2 |

The candidate's longest steady interval was in Low Warehouse B. It recorded 931.360 ms between render callbacks, 0.938 ms of process work, 0.154 ms of physics, and 0.049 ms of render setup CPU. The window had zero new surface, draw and specialization pipelines. The original revision also had a 603.403 ms steady frame at High Ashford workshop on this host. The reduced Harlow entry replicated. Warehouse B p99 approached its original value on this host. The direction of the cab, passenger-car and Medium fog differences varied across hosts. The earlier 952.577 ms results-screen frame did not recur in that cell. The two runs together demonstrate a continuing long-tail problem at different locations.

Linux and macOS each passed 305/305 tests. All six rendered ownership cases passed. The fresh ARM download passed 46 headless, 49 windowed and 81 packaged benchmark cases. Fresh Intel passed 46 headless checks. Another 23:30.42 default journey passed 167/167, escaped with zero travel teleports, and saved a complete recording. The two stress jobs failed. All six device losses were among the 20 cold High launches, five on the dedicated runner and one on the mixed runner. Six .ips reports are present. The other 89 scheduled processes were clean.

Build 77 has a different ZIP and pack digest from build 73. Comparing all 902 PCK table entries showed one changed entry, the UID cache. Its only mapping difference was the addition of the external test driver path. The other 901 entries had identical lengths, flags and content checksums. No game, shader or art entry changed. The existing build 73 remains the download tied to the large native Metal comparison.

[All 12 locations and startup phases](comparison/COMPARISON.md) · [Every stress category and individual process](stress/STRESS.md) · [Raw default timing, gameplay reports and stills](performance-and-journey-logs.zip) · [Full original artifact and second MP4](https://github.com/oiwdis/last-train-out/actions/runs/44682971897/artifacts/14609155020)

[Five dedicated High crash reports](release-stress-high.zip) · [Mixed crash report](release-stress-mixed.zip) · [Low/Medium](release-stress-low-medium.zip) · [Linux](linux-tests.zip) · [macOS](test-logs.zip) · [Rendered ownership](renderer-stress.zip) · [Fresh ARM](selftest-arm64.zip) · [Fresh Intel](selftest-x86_64.zip)

[Compared entry checksums and UID mapping](pack-entry-comparison.json) · [Build and archive identities](summary.json) · [Independent workflow](https://github.com/oiwdis/last-train-out/actions/runs/44682971897)
