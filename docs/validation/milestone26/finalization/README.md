# Finalization evidence index

The conclusions and limitations are in [the final review](../../../FINALIZATION_REVIEW.md)
and [performance report](../../../PERFORMANCE_FINALIZATION.md). A completed
measurement file alone does not prove a successful process or packaged launch.

| Evidence | Provenance and scope |
|---|---|
| `baseline-tests.json`, `baseline-tests.log` | Original `dfbfdf8`: all 187 checks pass. |
| `final-tests.json`, `final-tests.log`, `final-clean-import.log`, `final-main.log` | Godot 4.5.1, Linux, runtime candidate `10e99b3`: 196 checks, clean import and 600-frame main-scene smoke check. |
| `test-preservation.json` | All original 187 test names remain present and passing; nine added checks. |
| `clean-checkout-*` | Independent checkout at `ff3578f`: 196 checks with rebuilt UID/class/scene caches; compressed texture imports reused. |
| `selftest-source.json`, `selftest-source.log` | Source-level headless execution of the corrected packaged self-test at `dbfbdac`: 31 gameplay checks, exit 0. Its `exported_build: false` is intentional; native exported checks are separate. |
| `asset-check.json` | 31 self-contained GLBs and 137 explicitly compressed/mipmapped texture records. |
| `gallery-validation.json`, `gallery-*.log`, `visual-continuity.json` | All 51 images decode; 17 matched camera/lighting configurations. Source continuity and later preparation changes are documented. |
| `profile-before.*`, `profile-after.*` | Short software-Vulkan ablations: `dfbfdf8` versus the material/geometry pass at `8fbaa34`, before the later preparation and worker-budget changes. |
| `profile-intermediate-sss.*` | Intermediate investigation with skin scattering enabled, not a shipping preset result. |
| `render-warmup-*`, `worker-pool-*`, `render-shutdown-stack.log` | Controlled local route and shutdown investigation. Failed default-budget runs are retained alongside successful overrides and the shipping 0.9 candidate. |
| `shader-inventory-validation.json` | Two deterministic inventory rebuilds: 1,080 entries, matching SHA-256, no engine errors. |
| `native-ci24/` | Full short native comparison and failed windowed export test; optional non-shipping skin probe timed out. |
| `native-ci25/` | Cancelled after baking/signing during redundant texture reimports; compressed export log retained. Not a validated build. |
| `native-ci27/` | Successful final-revision preset/route processes; cancelled during ablations to advance the export fix. Incomplete comparative cohort. |
| `native-ci29/` | Complete 600-sample comparison, successful universal export and arm64 headless checks, failed windowed deadline. Predates the worker-budget change. |
| `native-ci32/` | Earlier Metal candidate `dbfbdac`: 196 native checks, complete 600-sample comparison and 11-assertion tour. Universal export/bundle/headless checks pass; graphical deadline fails, so no fresh-download checks or final ZIP. |
| `native-ci33/` | Same exported app/runner: default Metal rejects a baked shader for a newer Apple GPU; forced Vulkan passes 34 checks in 79.1 s. The workflow remains failed; no ZIP. Native log limitations retained. |
| `native-ci34/` | Final Vulkan runtime `c86d6f3`: 196 native checks, all eight 600-sample comparisons, universal ZIP integrity and launch reports. Source measurements are cache-conditioned; complete builds use different drivers. |
| `tour-media.json`, `tour.log` | Final capture from run 34: 1,358 frames, 56.583 s, Medium/Vulkan, 854×480 at fixed 24 FPS. Complete decode, SHA and eleven gameplay assertions verified; not a real-time benchmark. |
| `tour-headless.log` | Earlier script-only tour validation at `8fbaa34`; not evidence of graphical quality or the final driver. |

`native-ci34/delivery-status-attempt1.json` retains the failed packaged route
process despite passing ordinary launches. `native-ci34/attempt2/` and
`delivery-status-attempt2.json` record the successful same-ZIP repetition,
including all packaged benchmark cases. Latest exact-head results are linked
from PR #4. No physical 2020 M1 fullscreen result or combined Milestone
3 fog result is claimed.
