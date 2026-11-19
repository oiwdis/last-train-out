# Milestone 3.5.1 evidence index

Reference: `7df2f5abee54b8adcf27b8668263fba231a79033`. Runtime candidate:
`cc50670c9ae70aa2de7ce92185a229d284c075f8`. See the
[performance analysis](../../PERFORMANCE_MILESTONE351.md) and
[release review](../../MILESTONE351_REVIEW.md) for conclusions and open gates.

Raw attempts remain separated by provenance. A successful retry never replaces
a failed attempt. Hosted Apple Paravirtual results are not physical M1 results;
Linux llvmpipe probes are not hardware acceptance measurements.

| Evidence | Purpose / limits |
|---|---|
| [Baseline Linux](baseline/linux/) | Exact reference's 292-test suite and initial local startup probes |
| [Baseline native tests](baseline/native-tests/README.md) | All 292 original tests, native Godot 4.5.1 |
| [Baseline startup](baseline/native-startup/README.md) | Three native startups before runtime optimization; includes cache serialization failure |
| [Baseline matrix and sampling](baseline/native-matrix/README.md) | Two unsampled full matrices, separate profiler run, all failed/cache-error output |
| [Geometry](geometry-tests/native/README.md) | Construction optimization measurements; unfavorable cold launch/cache errors retained |
| [Linux investigations](investigation/linux/README.md) | Render timeouts, ownership reproductions, geometry fingerprints and corrected wrapper attempt |
| [Queue preparation](queue-preparation/README.md) | Startup/cache reuse, short 36-location/preset probe, rendered lifecycle and gameplay checks |
| [Repeated native processes](repeated-native/README.md) | Three full short matrices; remaining >100 ms entries retained |
| [Audio retirement](audio-retirement/README.md) | Failed native shutdown, exact WAV playback reproduction, 300 Linux tests and three corrected native startups |
| [Linux gameplay](gameplay/linux/README.md) | Continuous 167-check journey, failure/recovery scenarios and separate-process save/resume |
| [Runner queue history](investigation/runner-queue.json) | Cancelled/unassigned CI attempts; no fabricated test/build outcomes |

`summarize_paired.py` rebuilds the comparison tables and CSV distributions from
the final paired artifact's `comparison.json` and raw reports. It recomputes
pooled percentiles from individual frames and retains per-attempt rows.
`verify_startup_cache.py` checks three native readiness/shutdown logs and actual
persisted PSO reuse. Neither tool deletes raw measurements or ignores outliers.

The previous milestone's fatal Vulkan timeout, successful retry, original ZIP
and original recording remain in `docs/validation/milestone35` and
`docs/recording`. They are historical evidence, not a substitute for new release
validation. Physical M1 acceptance remains explicitly pending.
