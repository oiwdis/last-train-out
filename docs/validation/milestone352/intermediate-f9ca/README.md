# Intermediate f9ca998 native validation — superseded

[Run 44605742748](https://github.com/oiwdis/last-train-out/actions/runs/44605742748)
was deliberately cancelled after a new local early-exit fixture reproduced a
pending spatial-audio ownership timeout. The corrected helper is at `6038bfc`.
This was not a retry-to-pass GPU failure. Final acceptance must use the corrected
candidate's complete workflow and stress series.

Before cancellation this intermediate run passed all 302 macOS tests, three
native startup probes, six rendered lifecycle tests, the continuous journey,
fuel/fog/resume scenarios, universal export, bundle integrity and headless and
windowed exported launches. No final ZIP or new continuous recording was
published by this cancelled run.

The initial source-project readiness times were 74.367 / 18.580 / 17.469 seconds.
Six subsequent matched baseline/candidate startup processes completed, but the
first baseline matrix was interrupted. Its partial JSONL, logs and all six
startup reports are preserved in the unchanged test-log artifact. Do not treat
that incomplete comparison as final frame-pacing evidence.

`initial-startup.zip`, `renderer-stress.zip`, `export-and-selftest.zip` and
`cancelled-run44605742748-test-logs.zip` retain all completed/partial evidence.
Renderer teardown still reports the verbose engine `servers` StringName and a
MoltenVK informational GPU-allocation count at physical-device destruction.
Neither is silently removed; RSS/texture counters are not complete GPU heap
telemetry. The six-test renderer gate emitted no ObjectDB/resource-in-use
warning, but the later targeted early-exit failure explains why that is not
sufficient coverage on its own.
