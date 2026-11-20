# Independent repeats with the corrected log reader

A second workflow used the original signed 6038bfc app for shadow comparisons and the same frozen 5534cf8 candidate for native Metal, Mobile and the full controls-driven journey. Native launch cohorts had their own runner and user data. No failed process was retried within a cohort. The second shadow replica started after a runner became available. The new reader failed native Metal jobs on the sampler warning even when gameplay and process exit succeeded.

| Hosted job | Outcome | Preserved data |
|---|---|---|
| Candidate Forward+/Metal, dedicated High | 36/36 completed, 35 clean. Its all-preset seed warned. First cold High readiness took 144.937 s. | [Archive](followup-forward-metal-high.zip) |
| Candidate Forward+/Metal, mixed | 31/31 completed, 10 clean. Twenty-one emitted the sampler warning. First cold Low took 169.565 s. | [Archive](followup-forward-metal-mixed.zip) |
| Candidate Mobile/Vulkan, mixed | 31/31 clean. Cold readiness reached 59.586 s and one station entry reached 729.391 ms. The first cohort's 180 s failure is retained separately. | [Archive](followup-mobile-vulkan-mixed.zip) |
| Original Vulkan shadow replication A | 10/16 completed, six device losses, five native .ips files retained. | [Archive](../../exported-experiments/audit-shadow-a.zip) |
| Original Vulkan shadow replication B | 9/16 completed, seven device losses, seven native .ips files retained. | [Archive](../../exported-experiments/audit-shadow-b.zip) |
| Candidate Forward+/Metal, full exported route | 167/167 gameplay checks, zero travel teleports, one saved-position restoration, verified 23:30.42 MP4. The sampler warning failed strict acceptance. | [Archive with MP4](../native-metal-journey-audited.zip) |

Combined with the initial 95-process native Metal cohort, **162/162 processes completed, 91 were clean, 71 warned and zero lost the device**. Five were headless isolation probes and 157 rendered. These include 40 cold and 40 warm High launches across the two series. The earlier cold peaks were surpassed. In this repeat the worst of the 30 post-readiness frames was 250.236 ms on cold Low. The result establishes the observed launch/lifecycle mitigation on these hosts. It also rules out a claim of uniformly responsive startup.

[All Metal timing distributions and individual processes in the repeat](metal/STRESS.md) · [All Mobile repeats](mobile/STRESS.md) · [All five shadow cohorts, treatments and individual attempts](../../exported-experiments/EXPERIMENTS.md) · [Six original job logs](workflow-logs.zip) · [Workflow outcomes](https://github.com/oiwdis/last-train-out/actions/runs/44682971905)
