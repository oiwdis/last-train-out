# Original failures and superseded measurements

The investigation began with branch head 7f162d9 and game code 6038bfc. Both release-stress runs failed the same two cold High attempts. The two fresh ARM jobs failed at different points in the exported High workload. The original 6038 downloads are [preserved in 3.5.2](../../milestone352/final-native/README.md). This directory adds the corresponding unchanged-game repeat from [44625378022](https://github.com/oiwdis/last-train-out/actions/runs/44625378022). Both release-stress archives contain original macOS crash reports.

The first 3.5.3 commit be655bf added investigative tooling only. Its four-job [renderer experiment](https://github.com/oiwdis/last-train-out/actions/runs/44673670898) ran independently to completion. Its separate [ordinary app workflow](https://github.com/oiwdis/last-train-out/actions/runs/44673671118) repeated the unchanged game and was cancelled during the second candidate matrix to admit the changed runtime on PR #6. The completed 304-test suite, three startup probes, six rendered lifecycle checks, headless continuous route, build self-tests, first two matched matrices, partial next matrix and the existing baseline cache diagnostics are retained in the four `unchanged-*.zip` downloads. This incomplete cohort has no fresh-download acceptance result.

| Preserved download | GitHub artifact |
|---|---:|
| repeated-release-stress.zip | 14580858037 |
| repeated-fresh-arm.zip | 14580556928 |
| unchanged-startup.zip | 14601595796 |
| unchanged-renderer-stress.zip | 14602080414 |
| unchanged-partial-matrix.zip | 14601129644 |
| unchanged-export.zip | 14602097684 |

The diagnostic-only follow-ups kept the same shipped game source and targeted the original 6038 or candidate 5534 download by SHA-256. The branch's normal concurrency group replaced three pending duplicate app workflows before they acquired a runner. None executed an acceptance test. The actual 5534 release workflow continued independently.

[Superseded pending app run for f091e3c](https://github.com/oiwdis/last-train-out/actions/runs/44677062828) · [Superseded pending app run for 67a42ed](https://github.com/oiwdis/last-train-out/actions/runs/44679367082) · [Superseded pending app run for e5c65d5](https://github.com/oiwdis/last-train-out/actions/runs/44680567951) · [Tested build and all primary gates](https://github.com/oiwdis/last-train-out/actions/runs/44675841777)
