# Audio retirement race

Run [44579035899](https://github.com/oiwdis/last-train-out/actions/runs/44579035899), source 31a0e4a: all 299 native tests passed, but startup process 3 leaked three AudioStreamWAV/AudioStreamPlaybackWAV pairs. Processes 1 and 2 were clean. The strengthened gate correctly failed before export. Full logs and the failed attempt are retained in the ZIPs. No build or recording is claimed from this run.

A small Linux fixture with the same three duplicated fog loops reproduced all three live playback owners after stop(), stream=null, scene removal and two process frames. This is not the earlier coroutine leak. Godot 4.5.1 AudioServer.stop_playback_stream marks a fade-out for the mixer; playback_list.maybe_cleanup runs on a later main-thread update. Two fast graphics frames are not a guarantee of an audio mix/retirement cycle.

Diagnostics now track WeakRefs to the actual playbacks, stop their players, keep the diagnostic scene alive without simulation until those owners retire, then free the scene and drain frame callbacks. The bounded two-second failure path emits an error; it does not suppress warnings. Normal gameplay audio and fog behavior are unchanged. A six-cycle regression alternates paused/unpaused teardown and checks playback/scene ownership before completion. It passed locally without ObjectDB or WAV playback leaks. The first native startup validation after the fix is detailed below; exported checks and recording still require the full release run.

The separate `servers` verbose StringName maps to AudioServer's debug profiler label in engine source; that remaining engine-level diagnostic is preserved. The first test-development attempt had a GDScript inferred-Variant parse error; its raw log is also retained, followed by the typed fix.

## Native startup after the fix

[Run 44583438066](https://github.com/oiwdis/last-train-out/actions/runs/44583438066), `cc50670c9ae70aa2de7ce92185a229d284c075f8`: three processes reached readiness, exited zero and reported no ObjectDB, resource-in-use or other engine diagnostics. `native-startup-after.zip` retains every log, phase, RSS sample and process status. `native-cache-after.txt` verifies that process 1 saved a 10.4 MiB PSO cache and both warm processes loaded it with zero shader-code cache misses. The verbose engine-level `servers` StringName remains.

Readiness times were **107.173 / 29.977 / 25.575 seconds**. These unfavorable totals are retained: the audio fix is not a startup optimization, and these hosted results do not meet the startup target. Scene activation took 2.711 / 2.678 / 1.697 seconds; the first 32.810 seconds elapsed before the script initialized. This separate runner is not a matched before/after performance comparison. A few clean starts are evidence for the reproduced cleanup correction, not proof that every possible shutdown or fatal GPU timeout is fixed.
