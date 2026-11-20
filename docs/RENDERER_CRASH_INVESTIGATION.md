# Vulkan investigation for Milestone 3.5.3

## Incident and controls

Starting head `7f162d9437eccc4e1bd16a0f1a861dd1f1ff5172` differs from runtime `6038bfcd0f0c5427ae6c53435d2867282938f6e4` only in evidence and documentation. On both revisions the release-stress process sequence on fresh hosted macOS 26.7.2 arm64 runners (three logical CPUs, Apple Paravirtual GPU, Godot 4.5.1 Forward+, Vulkan via MoltenVK 1.2.9) failed on exactly the third and sixth cold launches. Both requested High. Four of six cold High processes across these two independent runners failed before readiness. All six warm High processes succeeded. Low and Medium completed their startup series. Cold here means a new writable app cache, with baked shaders and shared OS/driver caches. This is a conditional frequency in a fixed test order.

| Failed job | Last observed behavior |
|---|---|
| [6038 exported stress](https://github.com/oiwdis/last-train-out/actions/runs/44608806260/job/135898601991) | Cold High 3 and 6, 960×540, Dummy audio. Both reached the initial fog/world view and Platform, with 35 then 76 specializations. No mission-ready report. |
| [6038 fresh ARM](https://github.com/oiwdis/last-train-out/actions/runs/44608806260/job/135898602081) | Native audio. Headless passed, windowed reached mission readiness and movement/camera checks, then failed in the preset sequence. |
| [Same game, second stress runner](https://github.com/oiwdis/last-train-out/actions/runs/44625378022/job/135926229940) | Cold High 3 and 6 failed again. Both native reports and all 31 attempts survive in the artifact. |
| [Same game, second fresh ARM](https://github.com/oiwdis/last-train-out/actions/runs/44625378022/job/135926230017) | Headless and windowed mechanics passed. The packaged preset benchmark progressed through Low and Medium then died with SIGTRAP applying High. |

The Metal command buffer reports `kIOGPUCommandBufferCallbackErrorTimeout` (code 2) on the submit/present queue. MoltenVK returns `VK_TIMEOUT`, Godot's Vulkan fence wait fails and the engine traps after detecting device loss. The macOS reports place the main thread in `RenderingDeviceDriverVulkan::command_queue_execute_and_present → execute_chained_cmds → _execute_frame → swap_buffers → RenderingServerDefault::_draw → Main::iteration`. These are observation points following an asynchronous GPU failure. They do not locate an offending shader, command, resource or fence. Stdout/stderr ordering is buffered. The device lacks `VK_EXT_device_fault`.

The first two cold crashes reached 482.27 and 480.19 MiB sampled process RSS. The reported Vulkan budget was 4,778 MB. RSS omits driver allocations. No out-of-memory diagnostic was observed. Cold-start failures precede normal scene teardown, and the cold stress uses Dummy audio. The separately reproduced spatial-audio ownership issue occurred during shutdown. Runtime shader-code storage, baked shaders and driver PSO persistence are distinct. Cold failures start with a 0.0 MiB PSO cache. The baseline's nonfatal `VK_INCOMPLETE` while serializing a growing cache has a different signature.

[Original crash logs, native reports and every attempt](validation/milestone352/final-native/README.md) · [Second stress download](validation/milestone353/origin/repeated-release-stress.zip) · [Second ARM download](validation/milestone353/origin/repeated-fresh-arm.zip) · [Stress job log](validation/milestone353/origin/repeated-stress-job.log) · [ARM job log](validation/milestone353/origin/repeated-arm-job.log)

## Regression history before new experiments

The original integration already lost its device during High preparation. The identical ZIP passed on retry. `e69a275` moved intermediate mesh assembly onto the CPU and gave preparation a scene owner. `038033e` drew through the frame queue before releasing play. Together with the HUD invalidation fix in `2bf19f0`, these reduced the matched Harlow entry from 2,405 to 97 ms. A sampled baseline render thread waited in `_stall_for_frame → fence_wait → vkWaitForFences`. The `cc50670` audio change and later retirement changes affect teardown. `1cbd924` isolated the fog proxy and added three interior views. Five of six native attempts lost the device. `f9ca998` reverted that isolation and retained the views. `6038bfc` retired pending spatial players before awaiting mixer ownership.

In the 3.5.2 comparison, High Warehouse B p99 regressed from 39.59 to 49.00 ms at substantially unchanged draw/geometry/texture demand. The Medium dangerous-fog 389.657 ms frame had 382.899 ms in the render bracket, with no pipeline increments. Driver GPU timestamps were unavailable. Both steady-state regressions require their own comparison. Neither is explained by counting startup pipeline creations.

[Original failure and retry](validation/milestone35/native-final/README.md) · [Rejected fog isolation, all six attempts](validation/milestone352/preparation/README.md) · [Prior matched cohorts](PERFORMANCE_MILESTONE352.md)

## Predictions recorded before production changes

| Hypothesis | Discriminating experiment and observation |
|---|---|
| First-use fragment or shadow work exceeds a command-buffer time budget while specialized pipelines compile | Hold assets, output, backend, preset and queue rotation constant. Reduce pixels only during covered preparation, restore before ready. Separately vary one High feature or preparation cadence. Compare repeated cold and warm starts. |
| A fog shader or texture upload alone triggers the failure | Start with a camera, one light, three textured PBR draws and the actual fog shader. Remove fog, move identical uploads earlier, and compare to the complete mission. Rejection requires sufficient workload. |
| Too many queued preparations or unsafe retirement | Compare batched/incremental admission, removal during/after submission, and a diagnostic readback before/after activation. Use the public API only. A post-draw signal denotes submission. A process crash after a fence wait alone does not demonstrate a lifetime violation. |
| Cache I/O or cache miss causes the timeout | Isolate fresh writable caches, change shader-code and PSO storage separately, record actual load/save events and keep the baked pack constant in release stress. |
| High effects or renderer implementation matter | Compare the three supported method/driver pairs, confirm the actual pair at runtime, and retain unsupported features, visual captures, errors and timing for each. |
| Introduction lies in 3.5.1 or the extra 3.5.2 views | Interleave exact 7df2f5a, cc50670 and 6038bfc on a common runner. Measure steady frames separately from preparation. An earlier crash disproves a first introduction in a later revision, but cannot establish identical frequency. |

Godot 4.5.1 exposes Forward+ and Mobile on Vulkan and Compatibility on native OpenGL on macOS. Godot can fall back to another driver, so each rendered report must identify the actual backend. Mobile and Compatibility lack Forward+ SSAO and volumetric fog. The game checks volumetric storage-atomic support separately. The screen-space and lighting paths differ. The default remains Forward+/Vulkan.

[Godot 4.5 renderer feature matrix](https://docs.godotengine.org/en/4.5/tutorials/rendering/renderers.html) · [macOS display server in Godot 4.5.1](https://github.com/godotengine/godot/blob/4.5.1-stable/platform/macos/display_server_macos.mm) · [Frame queue, cache and transfer submission implementation](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/rendering_device.cpp)

## Isolated workload and synchronization

The standalone probe uses three 512×512 texture uploads, textured StandardMaterial3D surfaces, a shadowed directional light, the shipped fog shader and a camera. It has no train, physics, imported station, player or audio. The runner retains a flushed stage journal plus every measured frame. Its controlled diagnostic readback completes through Godot's public viewport texture API. No explicit fence or readback was added to gameplay. The Medium factor models Medium scale and MSAA on this small fixture. The complete-game comparisons use the actual presets.

The control and nine single-factor variants each completed three cold hosted starts. A separate run with Metal API Validation enabled also completed. **0/31 device losses** on Apple Paravirtual. The Linux llvmpipe sanity series completed 11/11. These observations put the small workload below the observed failure threshold and motivate the controlled full-game series. They do not rule out an interaction involving these components in the full game.

[Probe source](../tools/macos/renderer_probe.gd) · [Native logs, stages and Metal validation](validation/milestone353/probes/minimal-hosted.zip) · [Linux sanity evidence](validation/milestone353/probes/minimal-linux.zip)

The clustered renderer attempts its specialized graphics pipeline and can draw with a general shader while specialization is pending. The queue contains submitted work even after the CPU receives `frame_post_draw`. Godot rotates through at least two frames before reusing a frame fence. A successful wait orders that reuse, while a timeout surfaces an earlier GPU failure. The four cold High crashes all last reported 35 then 76 specializations. Two more native crash reports identify VirtualMac2,1. Their stacks do not identify a shader compiler failure or a dangling resource.

[Godot 4.5.1 clustered draw and shader selection](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp#L486) · [Vulkan driver](https://github.com/godotengine/godot/blob/4.5.1-stable/drivers/vulkan/rendering_device_driver_vulkan.cpp)

## Full mission and exact exported pack

On one hosted runner, 3 of 28 full-mission source processes lost the GPU. With preparation resolution reduced to 0.35× per axis the timeout followed Platform. With PSO persistence disabled it also followed Platform. With all preparation views disabled the mission printed readiness, then lost the device during the following frames. The latter case had no fog proxy, preparation camera, preparation submissions or camera retirement. Those operations and writes to the Godot pipeline cache are unnecessary for this failure to occur. Upload/specialization work during first visible use, lighting passes and a renderer/driver/device interaction remain possible. All three controls and the native validation run succeeded, which limits the strength of clean one-factor trials. No validation message identifies an invalid API operation.

An external script then instrumented the **original shipped executable and PCK**, checked both archive digests, selected a fresh writable cache per attempt and restored the exact preset before the final camera drain. On the first runner, untouched control, directional-only 1024 and positional-only 512 each lost one of four processes. The successful controls used the full 4096/2048 atlases throughout. The three corresponding failures last reported 357.38, 327.38 and 349.88 MiB of texture memory respectively, including the other scene textures at that point. Each reached 35 then 76 specializations. Each timed out before the restoration journal entry. Reducing both atlases completed four of four launches on this runner. The first independent replication lost one of four cold processes in **every** configuration, including both reduced together. All four emitted a real device-loss signature. The apparent 4/4 result on the first runner did not generalize. Production retains the original shadow atlases.

[Source experiments, all 28](validation/milestone353/probes/workload.md) · [Original pack, first shadow experiment and three crash reports](validation/milestone353/exported-experiments/original-export-shadows.zip) · [Corpus and renderer history on the three specified revisions](validation/milestone353/history/README.md)

The historical harness installed the same diagnostic teardown and time sampler in every checkout. Production diffs between cc50670 and 6038bfc add three interior preparation markers and explicitly copy the play camera's cull mask. Their effects occur before steady measurements. The other changes are diagnostic retirement and tests. The per-location raw draw counts and intervals are available alongside the source diffs. The High Harlow improvement was present at cc50670 in both longer historical acceptance data and the fresh three-way experiment. The original already suffered device loss, and the short three-way sample cannot assign onset of the higher cold High failure rate to an individual change.

[Production source diff](https://github.com/oiwdis/last-train-out/compare/cc50670c9ae70aa2de7ce92185a229d284c075f8...6038bfcd0f0c5427ae6c53435d2867282938f6e4) · [Historical frame distributions](validation/milestone353/history/pooled.csv)
