# Cold High Vulkan scene preparation

Two hosted Apple Silicon Macs ran the exact build 111 application at 960 × 540 with a private empty writable app cache for every start. Each host rotated four treatments through eight positions per treatment. Both used the same signed pack, camera fixture and integration shader bytes. The complete scene, the existing preparation views and the first 30 playable frames ran in each case. The temporary hidden-corridor and shader substitutions existed only in this diagnostic. [Fixture](../../../../tools/macos/vulkan_world_probe.gd) · [Both raw schedules](world-controls.json) · [Workflow](https://github.com/oiwdis/last-train-out/actions/runs/44868158489)

| Device losses / cold launches | Forward order | Reverse order |
|---|---:|---:|
| Full world, original camera at world origin | 4 / 8 | 0 / 8 |
| Replace only the six banks' material shader with the integration shader | 3 / 8 | 0 / 8 |
| Hide the entire visual corridor, keeping the world collision | 6 / 8 | 0 / 8 |
| Full world, first fog draw at the platform | 0 / 8 | 0 / 8 |

The clustered failures occurred on one of the two hosts. Substituting the old fog shader and hiding the corridor each left reproducible losses. Positioning the initial fog camera at the first covered platform view kept every visible asset and completed all sixteen launches. The result supports testing that placement in the real macOS High Vulkan player. Half the original controls were also on a host which had no losses in any arm. The experiment cannot identify the GPU command that timed out or establish a zero crash rate.

The revised player prepares the fog proxy at the platform on macOS High Vulkan. It still draws the full uncovered platform, every interior, and the final gameplay camera through the renderer's queue. The native Metal origin control and the original Low and Medium Vulkan setup are retained. A phase marker records the first view selected by the actual player. A separate two-host replication compares just the two camera positions in the build 111 pack. [Forward raw data including 13 failed starts](vulkan-world-forward.zip) · [Reverse raw data](vulkan-world-reverse.zip)

The Linux build passed all 312 tests and the four diagnostic variants each completed normal preparation in the software renderer. The portable test exercises the renderer, platform, preset and historical native control combinations. [Local regression suite and fixture checks](local-regression.zip)
