# Vulkan preparation after a preset change

Both hosted Apple Silicon Macs ran the same signed build 117 executable and game data. Each process started on Low with private application data and used the real preset, fog, Save, Continue and Restart controls. The ordinary arm left the first fog draw of each later High preparation at the platform. The other arm placed only that draw at the original world origin. Both recorded the real camera transform before the first draw. The order rotated within each Mac and began in opposite orders. Both arms shared each host’s driver cache. [Workflow](https://github.com/oiwdis/last-train-out/actions/runs/44877553109)

| Host | Later High camera | Processes | Completed full sequence | GPU device losses | Timeouts | Ended before a High camera was observed |
|---|---|---:|---:|---:|---:|---:|
| Forward | Platform | 4 | 1 | 3 | 0 | 0 |
| Forward | Origin | 4 | 3 | 1 | 0 | 1 |
| Reverse | Platform | 4 | 0 | 4 | 0 | 0 |
| Reverse | Origin | 4 | 4 | 0 | 0 | 0 |

Across both hosts the sequence completed on 1/8 processes using the platform on later High prepares and 7/8 using the origin. The two arms lost the device 7 and 1 times. Each successful process performed three High transitions, checked all four fog states, restored three saves and restarted the mission. Each table denominator includes failures before any treatment. Driver execution was asynchronous, and the hosted MoltenVK driver supplied no faulting GPU command.

Every platform loss followed the first observed later High preparation. The loss in the origin group occurred during the shared initial Low render, before any High draw or completed gameplay check. All seven processes reaching the later High origin completed the full sequence.

Cold High starts used a different schedule and have a separate replicated result. These samples do not establish physical M1 performance or a zero crash rate. [Cold default-camera and platform comparison](../replication/README.md) · [117 source and ordinary player failures](../../build-117/README.md) · [Per-process checks and last phases](results.json) · [Forward host logs, camera transforms and crashes](vulkan-preset-cycles-forward.zip) · [Reverse host logs, camera transforms and crashes](vulkan-preset-cycles-reverse.zip)
