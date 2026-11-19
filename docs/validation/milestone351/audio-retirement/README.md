# Audio retirement race

Run [44579035899](https://github.com/oiwdis/last-train-out/actions/runs/44579035899), source 31a0e4a: all 299 native tests passed, but startup process 3 leaked three AudioStreamWAV/AudioStreamPlaybackWAV pairs. Processes 1 and 2 were clean. The strengthened gate correctly failed before export. Full logs and the failed attempt are retained in the ZIPs. No build or recording is claimed from this run.

A small Linux fixture with the same three duplicated fog loops reproduced all three live playback owners after stop(), stream=null, scene removal and two process frames. This is not the earlier coroutine leak. Godot 4.5.1 AudioServer.stop_playback_stream marks a fade-out for the mixer; playback_list.maybe_cleanup runs on a later main-thread update. Two fast graphics frames are not a guarantee of an audio mix/retirement cycle.

Diagnostics now track WeakRefs to the actual playbacks, stop their players, keep the diagnostic scene alive without simulation until those owners retire, then free the scene and drain frame callbacks. The bounded two-second failure path emits an error; it does not suppress warnings. Normal gameplay audio and fog behavior are unchanged. A six-cycle regression alternates paused/unpaused teardown and checks playback/scene ownership before completion. It passed locally without ObjectDB or WAV playback leaks. Native repeated startup/export/recording still require a fresh run.

The separate `servers` verbose StringName maps to AudioServer's debug profiler label in engine source; that remaining engine-level diagnostic is preserved. The first test-development attempt had a GDScript inferred-Variant parse error; its raw log is also retained, followed by the typed fix.
