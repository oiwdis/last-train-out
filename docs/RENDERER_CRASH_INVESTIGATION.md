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


## Shadow replications and backend selection

The first three independent hosts ran the same four-condition, 16-launch experiment on the original High export. Control lost 3/12, directional-only 3/12, positional-only 6/12, and both reduced together 2/12. Two more hosts reproduced six and seven device losses. In all five cohorts, the loss counts were **4/20 control, 6/20 directional-only, 11/20 positional-only and 6/20 both**. All 27 timeout logs are retained. The archives contain 25 separate macOS .ips files for those 27 process losses. The raw process and exit records establish the two additional failures. Lowering covered shadow memory fails as a deterministic workaround and trades another resource reallocation for unproven protection. The game retains the original shadow sizes during every view.

The hosted Compatibility backend selected Apple's OpenGL software renderer, logged per-texture format conversion and timed out on every cold and warm launch in both source and export experiments. Mobile/Vulkan finished faster in several steady locations and preserved the character, car interiors and painted fog, but the original export timed out on its first cold Mobile start. The candidate's separate mixed Mobile cohort also exceeded 180 s on its first cold Low start. These are startup timeouts without the Vulkan-device-loss signature.

[Every original-export process and native crash archive](validation/milestone353/exported-experiments/EXPERIMENTS.md) · [Source renderer comparison and paired screenshots](validation/milestone353/backends/README.md)

## Cold native Metal startup

Godot also supports Forward+ directly on Metal on Apple Silicon. The universal pack under test was built for the project's Vulkan default. Godot 4.5.1's export baker selects one shader-container driver from the project's target platform settings, and its runtime includes the API name in the cache path. The first native Metal High launch in the 17-cold series logged 85 shader-cache misses, 38.742 s to the first script marker, 26.198 s loading scene/resources and 44.096 s from activation to mission readiness. The first surrounding-geometry/fog-material phase consumed 34.514 s within the last interval. Total readiness was 114.683 s. The next fresh-user launch also logged 85 misses yet finished in about 21 s on the same host. Fresh user caches do not reset OS, filesystem or driver state. Shader-cache misses alone do not explain the long first launch or identify the timeout on Vulkan.

[Godot 4.5.1 shader-baker target selection](https://github.com/godotengine/godot/blob/4.5.1-stable/editor/export/shader_baker_export_plugin.cpp#L58) · [Runtime cache lookup](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/renderer_rd/shader_rd.cpp#L438) · [First 17 cold and 17 warm native Metal High launches](validation/milestone353/alternatives/followup-forward-metal-high.zip)

## Current production signature

The candidate reproduced the timeout in 9 of 40 cold rendered launches and zero of 40 warm launches. Eight cold losses requested High and one requested Low. Seven were on the dedicated High runner and two on the mixed runner. The Low case last reported 20 specializations and 302,972,480 texture bytes after the fog/material view. Its next successful phase was never recorded. One dedicated High failure also stopped after the material view (35 specializations). The other seven High failures had reported Platform (76). Swap/present and queue-submit failures both occurred. The native reports still show a timeout on the submitting device followed by Godot's Vulkan fence failure and trap. A single shader count, one fixed scene transition, high-resolution shadows and High-only features are insufficient explanations.

The cold Low process followed the failed cold High process on the same runner. It had a separate writable directory and a separate process. OS/driver state was shared, so the sequence cannot establish whether the earlier loss affected the following process. All original failed processes, including the Low report, remain available.

[Full candidate startup and lifecycle counts](validation/milestone353/candidate/stress/STRESS.md) · [Mixed native reports](validation/milestone353/candidate/release-stress-mixed.zip) · [Dedicated High native reports](validation/milestone353/candidate/release-stress-high.zip)

The optional native Metal cohort on the exact release ZIP had zero device losses in 95 processes, including 20 cold High and 20 warm High. With default Vulkan, nine processes on that ZIP produced the native timeout and trap. The native Metal owner launch also passed all 49 normal windowed gameplay checks and emitted a sampler-capability warning. This is a verified hosted mitigation for the observed launch/lifecycle failure pattern. The offending command and upstream ownership remain unknown. The virtual GPU, drivers and OS caches differ from a physical M1, and the optional driver's first launch reached 126.599 s. The default remains unchanged pending physical evidence and an owner decision.

[Default cohort](validation/milestone353/candidate/stress/STRESS.md) · [Optional native Metal cohort](validation/milestone353/alternatives/metal/STRESS.md) · [Owner launcher validation](validation/milestone353/alternatives/native-metal-low-medium.zip)

## Native Metal sampler warning and capture correction

The first complete exported Metal journey reached escape, passed all 167 checks and recorded 16,925 frames in the engine. A warning correctly failed the recording gate. The old recorder checked diagnostics before encoding and its temporary AVI was removed at process exit. That attempt has its complete gameplay report, stills and original log, without a downloadable MP4.

The warning `Metal does not support LOD bias for samplers` also appears mid-line in 49 of the 95 original Metal stress logs and in the separate owner self-test. For example, stderr interrupted the text `Shader cache miss for Sce`. The original line-prefix check missed it. Re-reading the original bytes gives 95 successful exits/completions, zero device losses, 46 diagnostic-clean processes and 49 warned processes. All 40 cold/warm High launch logs were clean. The original default Vulkan cohort still has 86 clean processes and nine GPU losses. The raw archives are unchanged.

Godot adds `log2(min(render_scale, 1))` to the viewport's sampler bias. The project's scaled Low and Medium presets request a nonzero effective value. The native Metal backend logs once when that value is nonzero, then creates the sampler using its supported clamp and filtering parameters. Texture minification can consequently differ on that backend. This capability warning did not terminate the game, lose the GPU or indicate a surviving resource. It remains visible and fails strict diagnostics. No change to preset resolution or visual assets was used to silence it.

The release stress, paired frame measurement and recording readers now recognize embedded severity markers. The recorder encodes and validates a completed journey before returning failure for the diagnostic. Four Python regression checks exercise actual interleaving, bare driver-fault markers, renderer/lifetime errors and ordinary verbose output. The fresh-application checks also validate the resolved Vulkan driver. Re-auditing all 14 build, fresh, startup and rendered lifecycle process logs with the strict matcher found no diagnostics in those previously successful checks.

[First exported Metal journey with original warning and gameplay checks](validation/milestone353/alternatives/native-metal-journey-first.zip) · [Re-audited Metal stress](validation/milestone353/alternatives/metal/STRESS.md) · [Viewport effective bias](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/renderer_viewport.cpp#L267) · [Native Metal sampler implementation](https://github.com/godotengine/godot/blob/4.5.1-stable/drivers/metal/rendering_device_driver_metal.mm#L770)

Both public viewport setters for render scale and mipmap bias immediately reconfigure the render buffers in Godot 4.5.1. That path recreates samplers during each configuration. Trying to counter the automatic bias with a second setter can therefore submit an intermediate nonzero bias when switching between supported game presets. The game keeps its actual Low and Medium scale choices and the driver diagnostic. Changing resolution, rebuilding the root viewport or substituting a custom engine template solely to eliminate this warning would change the subject of the experiment.

[Viewport scale/bias setters](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/renderer_viewport.cpp#L1010) · [Render-buffer sampler allocation](https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.cpp#L102)

The repeated packaged native Metal route captured and independently decoded the complete 23:30.42 video. It again reached escape with 167/167 checks and emitted the sampler warning. This time the capture job retained the MP4 and then failed its release diagnostic as intended. The pack digest in the media report matches the development export.

[Corrected capture, exact PCK provenance, raw warning and video](validation/milestone353/alternatives/native-metal-journey-audited.zip)

Two additional candidate native Metal cohorts completed 67/67 processes, with zero device losses, 45 clean processes and 22 sampler warnings. The complete 162-process data set has 40 successful cold High and 40 successful warm High launches. The repeat's cold Low maximum was 169.565 s. This replication supports an opt-in hosted crash mitigation and preserves the startup and diagnostic blockers.

[Independent replications, strict gate results and original raw logs](validation/milestone353/alternatives/repeats/README.md)
