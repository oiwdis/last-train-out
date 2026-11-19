# Milestone 2.6 — environment continuation

Eight matched views compare `86b247337348ead8aaaf03f841c2277498f8b08e` with the environment continuation on `feature/milestone-2-6-photorealism`. Both use Godot 4.5.1 **Forward+**, **High**, **1280×720**, the same feet/camera/target/FOV and the same overcast lighting. The images are raw viewport captures; no image enhancement is applied.

The new assets include the CC0 factory kit and benches, original detailed freight containers/vans and roof assemblies, replacement supply props and sparse vegetation. Distant scenery, generic doors/ladders and several structural blocks remain visibly simplified; these images do not establish full photorealism.

The freight-yard camera is outside Warehouse B's trim in **both** versions. The original M2.6 gallery used a camera intersecting the trim and showed large clipped triangles. That old angle is not used for this comparison.

[Before camera poses](before/camera_poses.json) · [After camera poses](after/camera_poses.json) · [Capture verification and PNG checksums](capture.json)

| View | Before | After |
|---|---|---|
| Platform and hall windows | ![Before — Platform and hall windows](before/01_platform.png) | ![After — Platform and hall windows](after/01_platform.png) |
| Waiting-hall facade | ![Before — Waiting-hall facade](before/02_waiting_hall.png) | ![After — Waiting-hall facade](after/02_waiting_hall.png) |
| Station-house masonry and roof | ![Before — Station-house masonry and roof](before/03_station_house.png) | ![After — Station-house masonry and roof](after/03_station_house.png) |
| Warehouse A | ![Before — Warehouse A](before/04_warehouse_a.png) | ![After — Warehouse A](after/04_warehouse_a.png) |
| Warehouse B | ![Before — Warehouse B](before/05_warehouse_b.png) | ![After — Warehouse B](after/05_warehouse_b.png) |
| Freight-yard route | ![Before — Freight-yard route](before/06_freight_yard.png) | ![After — Freight-yard route](after/06_freight_yard.png) |
| Parked timber box vans | ![Before — Parked timber box vans](before/07_freight_car.png) | ![After — Parked timber box vans](after/07_freight_car.png) |
| Container doors and hardware | ![Before — Container doors and hardware](before/08_container.png) | ![After — Container doors and hardware](after/08_container.png) |

Reproduce with `tools/capture_environment.tscn`. Copy the exact same capture script to the baseline checkout and pass `-- --out=<directory>`. These stills are visual evidence, not frame-rate measurements.
