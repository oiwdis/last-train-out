# Build 108 as measured

Build 108 passed the automated suites, fresh-download checks and offline full journey. Its native Metal screenshots revealed black terrain on Medium. The material controls reproduced the defect. This revision is retained for comparison.

- [First-run gallery](https://github.com/oiwdis/last-train-out/blob/8c49608c3f67daced335a0d7228d163171ed54cd/docs/validation/milestone4/GALLERY.md) · [Original 96 PNGs](https://github.com/oiwdis/last-train-out/blob/8c49608c3f67daced335a0d7228d163171ed54cd/docs/validation/milestone4/native-pngs.zip)
- [All 16 locations and all presets](https://github.com/oiwdis/last-train-out/blob/8c49608c3f67daced335a0d7228d163171ed54cd/docs/validation/milestone4/FRAME_TIMES.md) · [Raw measured intervals](https://github.com/oiwdis/last-train-out/blob/8c49608c3f67daced335a0d7228d163171ed54cd/docs/validation/milestone4/raw-environment.zip)
- [Material controls](terrain-material-control.jpg) · [Threshold measurements](material-controls.json) · [Sources, signposts and 26 diagnostic PNGs](terrain-and-startup-investigation.zip)
- [Development ZIP receipt](development-build.json) · [All CI jobs and artifacts](workflow.json) · [Renderer stress](renderer-stress.json) · [Raw release checks](raw-release-checks.zip)
- [Complete continuous journey artifact with MP4](https://github.com/oiwdis/last-train-out/actions/runs/44850871725/artifacts/14688442055) · [Journey assertions and stream receipt](recorded-journey.zip) · [Decoded movie inspection](movie-motion.json)

The full film decodes to 16,930 frames. Frame 14,635 shows the same black terrain in ordinary first-person movement towards Crossing Stores. The camera and HUD continue through its two neighbors. The complete-frame pulse screen recorded this frame and confirmed zero all-black frames. [Frame and neighbors](blackwater-film-pulse.jpg)
