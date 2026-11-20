# Environment continuation gameplay recording

[Play/download the MP4](environment_tour.mp4).

The running Godot 4.5.1 game is captured with `tools/record_environment.tscn`:
Forward+, **Low**, **854×480**, offline Movie Maker at **24 FPS**, encoded as
H.264/AAC. This fixed playback rate is not a real-time performance measurement.
[Uncapped rendering measurements](../PERFORMANCE_ENVIRONMENT.md) are separate.

The tour visits the waiting hall, searches a modeled toolbox using E, walks
through Warehouse B in third person, switches to first person beside the timber
box van, and climbs the original ladder onto a replacement container's 2.7 m roof.
Location cuts are labeled on screen; scripted E/V and movement input drive the
actual gameplay systems. Four assertions verify search completion, perspective
switching, ladder attachment and the final roof height.

[Capture log and media metadata](../validation/milestone26/environment/) include
the interaction assertions, full decode check and SHA-256. The
[matched High screenshots](../screenshots/milestone26/environment/README.md)
show the same assets at 1280×720. The existing
[character/train tour](milestone26_tour.mp4) remains available for moving-car
traversal, inventory and cargo demonstrations.

Simplified structural elements, sparse clutter and approximate animation remain
visible. Full photorealism and physical M1 full-screen performance are incomplete
as described in the [milestone report](../MILESTONE_2_6.md).
