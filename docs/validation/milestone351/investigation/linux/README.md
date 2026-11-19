These are local Linux/llvmpipe investigations, not physical Mac performance.

* `local-short-matrix.log`: 960×540, 12 samples/8 settling frames; timed out
  after 240 seconds partway through Medium. No completed report. Retained.
* `cleanup-before.log`: legacy preset diagnostic, 320×180, 12 samples/8
  settling frames; timed out after 180 seconds during High preparation.
* `cleanup-nodraw-before.*`: same legacy preset logic with 3D explicitly
  disabled to isolate resource ownership from draw work. Exit zero, no
  ObjectDB/resource-in-use warning. Its frame rates are NOT game performance.
* `warmup-lifetime-before.log`: five small render-preparation fixtures, each
  freed after completion. Nodes/resources returned to a stable count.
* `cancel-lifetime-before.log`: five fixtures removed during preparation.
  Pause restored, no ObjectDB/resource-in-use warning. These small fixtures do
  not establish that the full rendered/exported diagnostic is leak-free.
* `lifecycle-leak-before.log`: the new full-scene cancellation regression did
  reproduce an ObjectDB leak. Verbose output identifies GDScriptFunctionState
  and the orphan `prepare`/`completed` names. Removing a GraphicsSettings node
  while it awaited the static RenderWarmup coroutine left that suspended state.
  The replacement scene-owned job signals completion during teardown instead
  of leaving a nested static coroutine. The same four tests subsequently passed
  without an ObjectDB warning (retained in `lifecycle-after.log`). This does not
  yet prove that every old exported-diagnostic warning had the same cause.
* `test-wrapper-interrupted-by-edit.log`: Godot completed 298/298 tests, but I
  edited the running shell wrapper while adding the shutdown-warning check.
  Bash then read a shifted file offset and failed its post-test commands. The
  raw attempt and 298-test JSON are retained; a fresh, unchanged-wrapper retry
  is required for a complete Linux validation result.

`geometry-comparison.json` compares pre-change and CPU-construction output
using Godot 4.5.1 headless. The baseline algorithm is unchanged from 7df2f5a.
All triangle positions and UVs match exactly; maximum normal component change
is 0.000215 after removing intermediate GPU attribute quantization. The unit
tests retain geometry fingerprints at 0.0001 precision, independent of indexing.

Godot's RenderingDevice mesh read path downloads vertex, attribute and index
buffers: https://github.com/godotengine/godot/blob/4.5.1-stable/servers/rendering/renderer_rd/storage_rd/mesh_storage.cpp#L637
Previously each generated box uploaded an intermediate mesh, downloaded it for
UV projection, and downloaded it again when appended into a ladder/column.
The revised construction retains CPU arrays and uploads only finished meshes.
Native before/after phase measurements are required before claiming a speedup.
