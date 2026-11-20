# Native run 45 — tests pass, windowed check times out

Source `140ce820c087d8a28734b7bab3ed14135d7cc527`; GitHub synthetic merge `628a3159465baaacc477164de2323bdceb29d711`. [Workflow](https://github.com/oiwdis/last-train-out/actions/runs/44459211814).

The full native suite passed **292/292** in 187.5 s with all 274 source identities preserved. Continuous journey, scarcity, natural fog death and cold moving-save checks passed; universal export, bundle verification and 46 ARM headless checks passed.

**The windowed check failed.** Its existing 120-second timer expired while preparing graphics presets, after the shipped mission and legacy fixture loaded and all checks reached so far passed. Mission readiness was 94.50 s after process start; Low and Medium preparation later took 17.57 and 4.63 s. The diagnostic Metal probe also expired, earlier in the check sequence, and never counted as a passing alternative. Logs retain the abrupt shutdown's resource/pipeline errors. No final app ZIP, performance cohort or full recording was produced by this attempt.

Commit `45c3b338a694f587b5290af0e8ce19208d0a702e` increases the combined exported self-test timer to 240 seconds, retaining every assertion and the launcher's 300-second wall-clock kill. This is a bounded test-budget change for loading two scenes and all presets, not a startup optimization. Long startup remains an acceptance limitation; the replacement native run must complete every check.
