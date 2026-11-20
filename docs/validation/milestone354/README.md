# Milestone 3.5.4 evidence

The starting PR revision is `2d7cd8d81588614edc4736a447ca57788f7f9360`. The first project-level sampler fix still produced a diagnostic on a camera-only scene. Its original positive control, failed candidate and images are in [baseline](baseline). The original native Metal process audit includes the severity marker even when stderr interrupted buffered stdout. [Warning audit](baseline/metal-warning-audit.csv)

The template build uses the official Godot 4.5.1 source commit. Build 86 contains the sampler correction. The later candidate also corrects worker shutdown. The compiler log records the source revision, Xcode version, patch hash and hash of the separately ad-hoc-signed runtime. Linux results include the original test IDs, the renderer log-scanner tests and the uninterrupted route. [Template build](template-build.zip) · [Local Linux suite](linux-candidate.zip) · [Local Linux launch and import attempts](local-linux.zip)

## Reproduce the tables

From the repository root, the following commands operate on downloaded workflow archives without running Godot. Each CSV retains source archive and attempt names. Metrics calculated from the original frame arrays have no trim or outlier cap. The first 60 entry frames and the subsequent 180 steady frames have separate rows. The 60 intervening settling frames are outside both measured windows. Additional screenshot processes perform a synchronous readback and have separate attempt rows.

```bash
cd docs/validation/milestone354
shopt -s nullglob
python3 ../milestone353/summarize_release.py metal-stress raw/metal-stress-*.zip
python3 ../milestone353/summarize_release.py vulkan-stress raw/release-stress-*.zip
python3 ../milestone353/summarize_lab.py matched raw/metal-drivers.zip
python3 summarize_frames.py raw/metal-drivers.zip matched
python3 summarize_startup.py startup raw/metal-*-first.zip raw/*libraries*.zip raw/metal-library-policy.zip raw/metal-stress-*.zip raw/release-stress-*.zip raw/fresh-native-metal-*.zip raw/gi-*.zip
python3 summarize_signposts.py startup/signposts.csv raw/*libraries*.zip raw/metal-library-policy.zip raw/fresh-native-metal-replay.zip raw/fresh-native-metal-signposts.zip raw/gi-*.zip
python3 compare_images.py raw/metal-drivers.zip raw/metal-art.zip gallery
python3 audit_movie.py ../../recording/milestone354-native-metal.mp4 movie-motion.json
```

The gallery uses Pillow. The motion audit uses FFmpeg and NumPy. The image table reports mean absolute differences on unmodified 8-bit source pixels. Each pair uses the same fixture and capture settings. Scaled JPEGs are navigation aids. The input PNGs, pose coordinates, startup logs, frame intervals and partial reports remain in the archives. Metal signpost wall times give the union of paired intervals within one operation type. Different types may overlap. Player-entry timestamps include the selector, GPU selection and shader-file setup. On the historic stock process, engine ticks begin inside Godot. A warm launch retains its private writable application cache. Operating-system and driver caches persist independently of the application cache.

The full findings, limitations and renderer decision are in the [milestone report](../../PERFORMANCE_MILESTONE354.md).
