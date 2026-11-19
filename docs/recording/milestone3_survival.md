# Fog survival gameplay recording

[Play the MP4](milestone3_survival.mp4). Godot 4.5.1, Low preset, Compatibility/OpenGL, offline Movie Maker at 24 FPS. The final run produced 2,715 frames (113.125 seconds). All **60 graphical checks passed**. The recording shows the M2.5 procedural assets with the new fog gameplay, not M2.6's unfinished art.

The sequence covers safe searching/departure; a critical Warehouse B search and abandoned heavy machine component; uninterrupted physical return, vaults, ladder boarding, roof-to-gangway descent and cab departure; recovery and sustained pursuit; coal carrying/drop; empty-boiler failure; deliberate exposure, damage and clear-air recovery; and a warned surge. Location/time/resource setup cuts are visibly captioned and listed in [the method report](../FOG_VALIDATION.md). It is a scripted scenario demonstration, not an unscripted playtest or a performance measurement.

Source: `tools/validate_fog_gameplay.gd` and `.tscn`. Input goes through the existing PlayerInput/reticle interactions. Nine PNGs are captured directly from the same final run. The logical canvas in `gameplay.json` is 1280 × 880; the physical captures are 1180 × 812 because the cloud window manager resized the requested 854 × 480 window. Inspect `recording-media.json` for the encoded stream dimensions.

Movie Maker reported an ObjectDB cleanup warning after all checks completed; no scenario failed. The full headless suite independently passed with no engine errors. The MP4 is encoded as H.264/AAC with fast-start metadata; complete decode and stream/audio checks are recorded alongside the raw gameplay log. Original synthesized fog/rail audio is included; no external music was added.

Reproduce (graphical display required):

```sh
godot --path . --audio-driver Dummy --rendering-method gl_compatibility --resolution 854x480 --fixed-fps 24 --write-movie /tmp/fog-survival.avi tools/validate_fog_gameplay.tscn
ffmpeg -i /tmp/fog-survival.avi -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart milestone3_survival.mp4
```

For a fast assertion-only rehearsal, replace Movie Maker/display flags with `--headless --fixed-fps 24`. That run does not prove rendering or audio playback.
