Run 53, https://github.com/oiwdis/last-train-out/actions/runs/44567054613,
source 948fa8965f379c18ffee94ab02b8451ae4b69a10. Instrumentation and CI changes
only; gameplay/rendering code is still the 7df2f5a baseline. Godot 4.5.1,
hosted Apple Paravirtual GPU, Vulkan, 960×540 windowed, Low. Not a physical M1.

The first windowed process had a fresh application shader/pipeline cache;
imports and the filesystem were already warm. The next two processes reused
the caches. Mission readiness was 70.947, 23.351 and 22.078 seconds from engine
ticks; process wall timings and approximate stdout arrival times are retained.

The first run logged a MoltenVK VK_INCOMPLETE pipeline-cache serialization
validation error despite exiting zero. This is an unfavorable result, not a
clean startup pass or a reproduction of the earlier VK_TIMEOUT device loss.
The exploratory wrapper originally recorded but did not fail on that error;
subsequent revisions make engine diagnostics fail the check as well.

All 292 native tests passed before these traces. The workflow was deliberately
cancelled after uploading startup evidence, before the remaining release gates.
It is not a release build.
