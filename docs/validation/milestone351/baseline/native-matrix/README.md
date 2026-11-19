`measurements.zip` is the complete unmodified artifact from run 54:
https://github.com/oiwdis/last-train-out/actions/runs/44567764672
Source 948fa8965f379c18ffee94ab02b8451ae4b69a10 (instrumentation only; no
gameplay/rendering optimization). SHA-256 of the ZIP:
`b63f7569d05842beb7a6277bb8d2382c9c9b3a5ecd0f5e8ae646fa365f26d06d`.

Two unsampled full matrices, then a separately sampled matrix. Each includes
all 12 locations × 3 presets, entry/steady raw frames, callback brackets, scene
transitions, CPU render submission, draws/primitives, texture/static memory and
external RSS. 960×540 windowed on hosted Apple Paravirtual/Vulkan. Not physical
M1 data. Sampling overhead must not enter a before/after FPS comparison.

The unsampled High Harlow entry peaks are 1,619.101 and 2,773.443 ms. In the
latter, 2,771.636 ms is inside the rendering callback bracket, 1.071 ms inside
process callbacks, and zero physics callback time. Pipeline-counter deltas are
zero. Sampled stacks show RenderingDevice::_stall_for_frame → Vulkan fence wait;
this localizes the wait to GPU/driver work, not a two-second gameplay callback.
It does not identify every operation performed by the hosted GPU.

The old 937.364 ms fog steady-state spike was not reproduced: unsampled High
near-fog steady maxima are 52.559 and 84.014 ms. That is NOT a fix claim. Other
unfavorable samples remain, including a 658.909 ms Medium passenger-car frame,
1,181.718 ms Medium warehouse entry and 162.748 ms High near-fog entry.

The first matrix logs four MoltenVK VK_INCOMPLETE cache-write validation errors.
All processes exited zero and completed, but that first attempt is not clean.
No fatal VK_TIMEOUT/device-loss or ObjectDB leak occurred in these three runs.
Successful repetitions do not resolve the previous device-loss incident.
