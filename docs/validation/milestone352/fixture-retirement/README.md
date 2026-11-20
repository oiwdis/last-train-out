# Rendered test-fixture audio retirement

A repeat of unchanged gameplay at documentation commit 5be9f80 failed [native run 44601576522](https://github.com/oiwdis/last-train-out/actions/runs/44601576522). All 300 tests and three startups passed; all five rendered lifecycle assertions also passed, but shutdown leaked five WAV/playback owners. The strict gate failed correctly. The complete failed test-log artifact is retained unchanged.

The existing scene retirement helper was used by startup probes, benchmarks, exported self-tests and recording, but TestSuite.free_spawned still queued scene deletion and waited only two physics frames. That path can outrun the audio mixer. A new regression reproduced all three active fixture playback owners remaining alive after free_spawned, with an ObjectDB warning. The test now passes after fixture teardown uses the existing bounded ownership-based retirement helper. No warning is suppressed, no assertion is weakened, and native verification is still required.

Linux validation: 302/302 in 141.3 seconds, including all 300 original test identities. The targeted two-test suite passes headless and windowed OpenGL. The windowed verbose log retains the known engine `servers` StringName; no ObjectDB or resource-in-use warning remains in this run.
