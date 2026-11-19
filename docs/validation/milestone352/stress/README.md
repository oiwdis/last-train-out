# Release stress methodology

`tools/macos/stress_release.py` runs the actual exported executable against an
identical copied PCK (SHA-256 checked), without modifying the signed bundle.
Godot 4.5.1 loads the owned `override.cfg` beside the explicit `--main-pack`.
A headless preflight verifies the private user-data path before the series.
Normal saves/settings are neither deleted nor moved.

The predetermined series is one preflight, ten fresh writable-cache launches,
one explicit all-preset cache seed, ten warm launches, and three rounds of:

* Three Save/Continue cycles with actual button input, a Restart, and twelve
  Low → Medium → High → Low transitions with fog activation during preparation.
* Exit while a preparation job is active, checking controller release and pause.
* All twelve station/interior/fog/completion fixtures on all three presets.

No failed attempt is replaced by a retry. Partial reports, stderr/stdout, exit
codes, timeouts, cache inventories/events, process RSS and new crash reports are
retained. Every child has a deadline; the series has a 40-minute limit and records
unstarted attempts as skipped/failing if exhausted. The workflow has 45 minutes
to leave time for evidence upload. Any warning/error, device loss, missing report
or failed assertion fails the check. The original signed app's pack and the
externally used pack must have identical bytes. This is a lifetime/rendering
fixture series; the separate continuous recording proves actual route gameplay.

“Cold” means an empty writable application cache. Exported baked shaders and
shared filesystem/OS/driver caches remain; this is not cold hardware. All native
measurements are 960×540 windowed. Fullscreen physical-M1 acceptance is separate.

Local headless diagnostic development passed 35 cycle checks and three
cancellation checks. These do not exercise Vulkan. The initial new-script type
annotation parse failure is retained, along with the corrected logs/reports.
Native final-series results remain pending until its artifact is collected.
