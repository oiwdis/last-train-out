Run 55: https://github.com/oiwdis/last-train-out/actions/runs/44571389208
Source e69a275342408cbdddababf43c075a1769cdcbbf. Native tests: 298/298, including
all original 292 identities. The source includes CPU mesh construction and the
scene-owned preparation job, but NOT the later GPU-queue drain/cache change.

Warm scene activation fell from 6.7–7.1 seconds in the earlier baseline to
1.56–2.17 seconds. StationArt fell from 3.3–3.45 seconds to 0.22–0.37 seconds.
These are different hosted runners, so the final paired comparison is still
required. Total warm readiness did NOT improve clearly: 24.901/22.591 seconds
versus baseline 23.351/22.078. The cold-ish first process was worse: 96.417
seconds versus 70.947, with two MoltenVK cache-write errors. All raw traces are
retained, including that unfavorable result.

The workflow correctly failed its new startup diagnostics gate. No release
artifact or rendered stress-test success is claimed from this run.
