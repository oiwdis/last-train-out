# Linux controls-driven evidence

These headless Godot 4.5.1 runs validate gameplay, not rendering speed or native macOS delivery.

- `continuous-journey.json` / `.log`: 166 checks, three stations, workshop salvage and abandonment under approaching fog, actual Save/Continue buttons at Blackwater, and escape. Zero travel teleports; one separately counted save restoration. The exact checkout was `c2857bbbbb2745dbbb9107bcc2b89630ff7459af`, including the wheel/rail and HUD fixes.
- `fuel-shortage-gameplay.json` / matching log: 35 checks, natural initial-fuel exhaustion and recovery with the collected sack, at `4630e703`.
- `stranded-gameplay.json` / matching log: 24 checks, natural fog advance, exposure and death, at `4630e703`.
- `process-resume.json` / write/read logs: 17 read checks across a fresh process, including camera, rig, rods and gauges. This is explicitly a constructed moving-save fixture, not evidence of uninterrupted travel.
- `played-blackwater-save.json`: the Save Game output from the successful controls-driven primary journey.

The native final-build reports and recording are linked from [the integration review](../../../MILESTONE35_REVIEW.md). Their exact source provenance takes precedence for delivered-build acceptance.
