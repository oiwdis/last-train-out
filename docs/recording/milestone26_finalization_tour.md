# Finalization gameplay recording

[Play the recording](milestone26_finalization_tour.mp4).

The tour runs the actual main scene in Godot 4.5.1 with the Medium preset,
Forward+ Vulkan through MoltenVK, 854×480. Godot Movie Maker advances gameplay at a fixed 24 FPS;
this is an offline gameplay capture, **not a real-time performance benchmark**.
It runs on the hosted Apple Silicon runner only after all timed benchmarks.
The matched still gallery uses software Vulkan; this tour uses the hosted Apple GPU.

The source is `tools/record_finalization.gd`. Movement, jump and E interactions
use the controller's scripted-input path. V is a real `InputEventKey`. Location
cuts are explicitly captioned; this is a compact tour, not one uninterrupted
walk around the map. Cargo remains the actual discovered `WorldItem` through
pickup, perspective switching, walking, drop/recovery and storage. The storage
transfer invokes the same `deposit_all()` operation used by its UI button.
The wheel close-up follows the actual moving locomotive, and the gantry climb
uses E and the existing movement/traversal controller through top-out.

The tour demonstrates the character inspection, walk/sprint/jump/landing,
first/third-person switching, cab departure, moving crew-car traversal, quartered
rods, Warehouse A searches, carrying in both perspectives, recovery and train
storage, Warehouse B, freight yard, ladder climbing and the distant environment.
Eleven assertions cover actual interaction/ownership results. Their log and the
media report are retained with the finalization validation evidence.

`tools/macos/record_finalization.py` makes the raw Movie Maker AVI, encodes H.264
(CRF 19, yuv420p) with AAC, checks its complete decode, dimensions, frame rate and
duration, and records the source commit and SHA-256. Reproduce on a graphical Mac:

```sh
python3 tools/macos/record_finalization.py /path/to/Godot tests/_output/visual
```

The checked recording contains **1,358 frames / 56.583 seconds**, 854×480 at 24 FPS.
It was captured and fully decoded in [Mac CI run 34](https://github.com/oiwdis/last-train-out/actions/runs/43797534032).
Its source is `c86d6f31ffaef820e72994cc031a317634bd8c57`; GitHub used PR
validation commit `aaedb630cb854be1e0ebdf124ee3ca98361be064`, whose tree
`97f13e5db29d36c69167be1f8e239ef9218ddf98` is identical. Preparation pauses add
14 frames before gameplay compared with the earlier capture.

SHA-256: `519c9a74923307e42b4494c11bc3cc93e047f7484046cae405c2b4c000969f58`.

The full recording and separate motion sequences for grips and gantry top-out
were inspected. The first-person hands are continuous and the carried sack is
the same physical item across view changes. Fingers retain authored arcs; ladder
contact blends and the neutral face remain less natural than motion-captured
performance. The evidence does not claim AAA photorealism.
