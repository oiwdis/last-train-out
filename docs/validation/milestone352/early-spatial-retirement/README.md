# Exit before the first spatial-audio physics tick

The added windowed exit-during-preparation fixture exposed an audio-retirement
timeout with one playback still owned. Normal startup, six native rendering
tests and the 35-check windowed lifecycle scenario had all passed; they do not
exercise exactly the same early-exit point.

The first hypothesis was starvation of main-thread audio updates during an
expensive render frame. Requiring three update opportunities in addition to
the two-second wall deadline fixes a real deadline boundary (new regression
fails before it), but **did not fix the windowed early-exit timeout**. That
failed timing-only experiment is retained as `window-exit-prep-fixed.log`;
the filename records the attempted fix, not a passing result.

Engine-source inspection then identified the remaining owner:
[AudioStreamPlayer3D::play/stop in Godot 4.5.1](https://github.com/godotengine/godot/blob/4.5.1-stable/scene/3d/audio_stream_player_3d.cpp).
`play()` retains `setplayback` until the first physics update. `stop()` clears
the playback list and pending start flag, but does not clear that separate Ref.
A game paused for preparation can be retired before the engine sound ever gets
its first physics update. Waiting for that Ref while keeping its node alive is
the wrong ownership order, regardless of a longer timeout.

The retirement helper now stops/clears spatial players and queues their nodes
for deletion before waiting for actual mixer owners. The retiring scene is
already disabled; RailAudio and FogAudio's routed-player cleanup check validity.
Normal gameplay playback is unchanged. The helper still fails a retained owner
after both its real-time deadline and main-thread update opportunities, and the
outer launch harness retains its process deadline. No warning is filtered out.

The new spatial regression reproduces the timeout before the change (3 passed,
1 failed) and passes after it (4/4). The earlier deadline regression separately
failed before its change (2 passed, 1 failed, with leaked WAV/playback owners)
and passed afterward. Complete raw logs/reports are retained. Final windowed,
full-suite and native release validation follow these focused checks.

Final local validation: 304/304 Linux tests in 138.9 seconds, all 300 original identities preserved; the windowed early-exit fixture now has no retirement timeout or ObjectDB warning. A separate normal-main-scene `--quit-after 2 --graphics=high` process exited during preparation without ObjectDB/resource-in-use warnings. These rendered checks use Linux llvmpipe/OpenGL at 320×180, so their timing is not macOS performance evidence. The logs retain the environment V-sync warning and verbose engine `servers` StringName.

Final native evidence now includes 304/304 tests, six rendered lifecycle cases,
the full journey recording and 29 successful exported stress processes without
the reproduced ObjectDB/resource-in-use warnings. Three separate final-candidate
Vulkan device losses (two cold High launches and one fresh ARM preset test) block
release acceptance; crashed processes are not cleanup passes. See the
[complete final report](../../../PERFORMANCE_MILESTONE352.md).
