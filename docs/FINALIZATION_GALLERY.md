# Milestone 2.6 final comparison gallery

Seventeen matched views cover all sixteen requested categories (walking and
running have separate images). Columns show original M2.5 (`8cde10c`), previous
M2.6 (`dfbfdf8`), and this finalization. Click an image for the original 960×540 PNG.

Godot 4.5.1, Forward+ Vulkan, High, native 960×540, identical camera/target/FOV
and scripted input sequence. Captures use software Vulkan; their capture speed
is not a gameplay-performance result. All revisions use the final licensed HDR,
ambient light, haze and SSAO through a capture-only fixture. Moon direction,
energy and tonemapping are identical in the original source scenes. Local
fixtures remain those authored in each revision. M2.5 originally used a solid
night sky; this controlled gallery compares artwork under common outdoor light.
The baselines' gameplay, geometry and textures are unchanged. Final images were
captured at `8fbaa34`; subsequent export and pipeline-preparation changes preserve
these visual assets, preset material states and poses.
[Source continuity check](validation/milestone26/finalization/visual-continuity.json)
records the later startup/preparation differences.

Camera metadata is included in each image directory. Walk/run, carry and wheel
views are sampled from the actual controllers; the four static character angles
use the same neutral idle sample. The first-person view uses the separate arms.
See [the gameplay recording](recording/milestone26_finalization_tour.mp4) for
movement and interactions, and [the final review](FINALIZATION_REVIEW.md) for
limitations and performance measurements.

## Character face

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Character face — M2.5](screenshots/milestone26/finalization/milestone25/01_character_face.png)](screenshots/milestone26/finalization/milestone25/01_character_face.png) | [![Character face — previous M2.6](screenshots/milestone26/finalization/previous26/01_character_face.png)](screenshots/milestone26/finalization/previous26/01_character_face.png) | [![Character face — finalization](screenshots/milestone26/finalization/after/01_character_face.png)](screenshots/milestone26/finalization/after/01_character_face.png) |

## Character front

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Character front — M2.5](screenshots/milestone26/finalization/milestone25/02_character_front.png)](screenshots/milestone26/finalization/milestone25/02_character_front.png) | [![Character front — previous M2.6](screenshots/milestone26/finalization/previous26/02_character_front.png)](screenshots/milestone26/finalization/previous26/02_character_front.png) | [![Character front — finalization](screenshots/milestone26/finalization/after/02_character_front.png)](screenshots/milestone26/finalization/after/02_character_front.png) |

## Character side

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Character side — M2.5](screenshots/milestone26/finalization/milestone25/03_character_side.png)](screenshots/milestone26/finalization/milestone25/03_character_side.png) | [![Character side — previous M2.6](screenshots/milestone26/finalization/previous26/03_character_side.png)](screenshots/milestone26/finalization/previous26/03_character_side.png) | [![Character side — finalization](screenshots/milestone26/finalization/after/03_character_side.png)](screenshots/milestone26/finalization/after/03_character_side.png) |

## Character rear

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Character rear — M2.5](screenshots/milestone26/finalization/milestone25/04_character_rear.png)](screenshots/milestone26/finalization/milestone25/04_character_rear.png) | [![Character rear — previous M2.6](screenshots/milestone26/finalization/previous26/04_character_rear.png)](screenshots/milestone26/finalization/previous26/04_character_rear.png) | [![Character rear — finalization](screenshots/milestone26/finalization/after/04_character_rear.png)](screenshots/milestone26/finalization/after/04_character_rear.png) |

## Walking

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Walking — M2.5](screenshots/milestone26/finalization/milestone25/05_walking.png)](screenshots/milestone26/finalization/milestone25/05_walking.png) | [![Walking — previous M2.6](screenshots/milestone26/finalization/previous26/05_walking.png)](screenshots/milestone26/finalization/previous26/05_walking.png) | [![Walking — finalization](screenshots/milestone26/finalization/after/05_walking.png)](screenshots/milestone26/finalization/after/05_walking.png) |

## Sprinting

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Sprinting — M2.5](screenshots/milestone26/finalization/milestone25/06_sprinting.png)](screenshots/milestone26/finalization/milestone25/06_sprinting.png) | [![Sprinting — previous M2.6](screenshots/milestone26/finalization/previous26/06_sprinting.png)](screenshots/milestone26/finalization/previous26/06_sprinting.png) | [![Sprinting — finalization](screenshots/milestone26/finalization/after/06_sprinting.png)](screenshots/milestone26/finalization/after/06_sprinting.png) |

## Heavy-object carrying

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Heavy-object carrying — M2.5](screenshots/milestone26/finalization/milestone25/07_heavy_carry.png)](screenshots/milestone26/finalization/milestone25/07_heavy_carry.png) | [![Heavy-object carrying — previous M2.6](screenshots/milestone26/finalization/previous26/07_heavy_carry.png)](screenshots/milestone26/finalization/previous26/07_heavy_carry.png) | [![Heavy-object carrying — finalization](screenshots/milestone26/finalization/after/07_heavy_carry.png)](screenshots/milestone26/finalization/after/07_heavy_carry.png) |

## First-person hands

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![First-person hands — M2.5](screenshots/milestone26/finalization/milestone25/08_first_person_hands.png)](screenshots/milestone26/finalization/milestone25/08_first_person_hands.png) | [![First-person hands — previous M2.6](screenshots/milestone26/finalization/previous26/08_first_person_hands.png)](screenshots/milestone26/finalization/previous26/08_first_person_hands.png) | [![First-person hands — finalization](screenshots/milestone26/finalization/after/08_first_person_hands.png)](screenshots/milestone26/finalization/after/08_first_person_hands.png) |

## Locomotive exterior

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Locomotive exterior — M2.5](screenshots/milestone26/finalization/milestone25/09_locomotive.png)](screenshots/milestone26/finalization/milestone25/09_locomotive.png) | [![Locomotive exterior — previous M2.6](screenshots/milestone26/finalization/previous26/09_locomotive.png)](screenshots/milestone26/finalization/previous26/09_locomotive.png) | [![Locomotive exterior — finalization](screenshots/milestone26/finalization/after/09_locomotive.png)](screenshots/milestone26/finalization/after/09_locomotive.png) |

## Moving locomotive wheels

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Moving locomotive wheels — M2.5](screenshots/milestone26/finalization/milestone25/10_moving_wheels.png)](screenshots/milestone26/finalization/milestone25/10_moving_wheels.png) | [![Moving locomotive wheels — previous M2.6](screenshots/milestone26/finalization/previous26/10_moving_wheels.png)](screenshots/milestone26/finalization/previous26/10_moving_wheels.png) | [![Moving locomotive wheels — finalization](screenshots/milestone26/finalization/after/10_moving_wheels.png)](screenshots/milestone26/finalization/after/10_moving_wheels.png) |

## Locomotive cab

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Locomotive cab — M2.5](screenshots/milestone26/finalization/milestone25/11_cab.png)](screenshots/milestone26/finalization/milestone25/11_cab.png) | [![Locomotive cab — previous M2.6](screenshots/milestone26/finalization/previous26/11_cab.png)](screenshots/milestone26/finalization/previous26/11_cab.png) | [![Locomotive cab — finalization](screenshots/milestone26/finalization/after/11_cab.png)](screenshots/milestone26/finalization/after/11_cab.png) |

## Passenger car interior

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Passenger car interior — M2.5](screenshots/milestone26/finalization/milestone25/12_crew.png)](screenshots/milestone26/finalization/milestone25/12_crew.png) | [![Passenger car interior — previous M2.6](screenshots/milestone26/finalization/previous26/12_crew.png)](screenshots/milestone26/finalization/previous26/12_crew.png) | [![Passenger car interior — finalization](screenshots/milestone26/finalization/after/12_crew.png)](screenshots/milestone26/finalization/after/12_crew.png) |

## Station platform

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Station platform — M2.5](screenshots/milestone26/finalization/milestone25/13_platform.png)](screenshots/milestone26/finalization/milestone25/13_platform.png) | [![Station platform — previous M2.6](screenshots/milestone26/finalization/previous26/13_platform.png)](screenshots/milestone26/finalization/previous26/13_platform.png) | [![Station platform — finalization](screenshots/milestone26/finalization/after/13_platform.png)](screenshots/milestone26/finalization/after/13_platform.png) |

## Warehouse A

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Warehouse A — M2.5](screenshots/milestone26/finalization/milestone25/14_warehouse_a.png)](screenshots/milestone26/finalization/milestone25/14_warehouse_a.png) | [![Warehouse A — previous M2.6](screenshots/milestone26/finalization/previous26/14_warehouse_a.png)](screenshots/milestone26/finalization/previous26/14_warehouse_a.png) | [![Warehouse A — finalization](screenshots/milestone26/finalization/after/14_warehouse_a.png)](screenshots/milestone26/finalization/after/14_warehouse_a.png) |

## Warehouse B

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Warehouse B — M2.5](screenshots/milestone26/finalization/milestone25/15_warehouse_b.png)](screenshots/milestone26/finalization/milestone25/15_warehouse_b.png) | [![Warehouse B — previous M2.6](screenshots/milestone26/finalization/previous26/15_warehouse_b.png)](screenshots/milestone26/finalization/previous26/15_warehouse_b.png) | [![Warehouse B — finalization](screenshots/milestone26/finalization/after/15_warehouse_b.png)](screenshots/milestone26/finalization/after/15_warehouse_b.png) |

## Freight yard

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Freight yard — M2.5](screenshots/milestone26/finalization/milestone25/16_freight_yard.png)](screenshots/milestone26/finalization/milestone25/16_freight_yard.png) | [![Freight yard — previous M2.6](screenshots/milestone26/finalization/previous26/16_freight_yard.png)](screenshots/milestone26/finalization/previous26/16_freight_yard.png) | [![Freight yard — finalization](screenshots/milestone26/finalization/after/16_freight_yard.png)](screenshots/milestone26/finalization/after/16_freight_yard.png) |

## Distant environment

| M2.5 | Previous M2.6 | Finalization |
|---|---|---|
| [![Distant environment — M2.5](screenshots/milestone26/finalization/milestone25/17_distant_environment.png)](screenshots/milestone26/finalization/milestone25/17_distant_environment.png) | [![Distant environment — previous M2.6](screenshots/milestone26/finalization/previous26/17_distant_environment.png)](screenshots/milestone26/finalization/previous26/17_distant_environment.png) | [![Distant environment — finalization](screenshots/milestone26/finalization/after/17_distant_environment.png)](screenshots/milestone26/finalization/after/17_distant_environment.png) |

