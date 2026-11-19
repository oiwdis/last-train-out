# The Harlow Escape

Milestone 3 continues on draft PR #5. The normal main scene is now `scenes/missions/harlow_escape.tscn`, an inherited version of the existing Harlow sandbox. The original `scenes/main/main.tscn` remains available to the original mechanics tests. No Milestone 2.6 assets were copied into this branch.

## Play

WASD moves, Shift sprints, V switches perspectives, E uses the object under the reticle, Tab opens the supply ledger, and G drops heavy cargo. **J opens the route ledger, pauses the world, and exposes Save Game, Continue Game, New Game and Restart Mission.** The inventory ledger continues to leave the world running. New Game offers a seed and Gentle / Standard / Severe difficulty; Restart retains the current seed and difficulty. New Game does not erase an existing saved game.

1. Search Harlow's departure coal reserve on the platform. Carry the revealed sack to the supply hold on the flatcar. E opens storage; R deposits inventory and held cargo. Walk onto the open deck, around its crates and through the crew car into the cab. Look at the boiler bunker to stoke one stored sack, then use the regulator.
2. The service brake stops at Ashford. Its platform reserve and freight warehouse contain guaranteed coal. The distant workshop offers tools, scrap and a heavy machine component; the depot office holds medicine. Deposit coal and stoke the boiler before continuing. Two Ashford sacks provide a comfortable fuel margin; one requires another stop for coal at Blackwater.
3. Blackwater's station holds food, the evacuated residence holds medicine, and Crossing Stores holds the evacuation log. The maintenance shed has a reserve coal sack. Read the log, gather food and medicine, return aboard and depart east.
4. Reach the escape boundary alive and aboard with all objectives complete. The results ledger records status, survival time, visited station IDs, collected supplies, distance, peak exposure and exposure duration. Driving through without the required objectives produces an incomplete result; death produces failure.

Buildings provide limited fog protection. The cab is not permanent safety. Previously visited stations remain engulfed as the front advances. The train uses fuel whenever it is operating, including acceleration and braking; it uses no fuel when stopped. Running dry applies the existing service brake and prevents restarting until the boiler is stoked.

## Route and stations

`JourneyDefinition` owns content and pacing; `FogRoute` remains the route authority. The authored itinerary is about 4.26 km. Exact distances are calculated from baked curve arc lengths, not world X coordinates:

| Stable ID | World position at stop | Approximate progress | Identity |
|---|---|---:|---|
| `harlow` | (15, 0, -3.5) | 0 km | Existing station, introductory coal and original scavenging district |
| `ashford` | (1815, 6, 180) | 1.82 km | Fuel tanks, freight containers, platform, freight warehouse, depot office, distant workshop |
| `blackwater` | (3415, 2, -80) | 3.46 km | Road crossing, station, evacuated residence, maintenance shed, distant supply warehouse/log |
| `escape` | (4215, 2, -80) | 4.26 km | Eastbound mission boundary |

Segments `harlow_ashford`, `ashford_blackwater`, and `blackwater_escape` carry stable IDs, Curve3D endpoints/baked lengths, outgoing links, connected stations and environmental metadata. The middle leg crests at about 14 m elevation. Station approaches stay level and straight. A future dispatcher can select a different ordered itinerary through the outgoing links; this milestone does not implement branch selection.

The train keeps its existing acceleration, smooth braking, wheel animation and AnimatableBody3D platform physics. Each car samples the same curve at its individual offset. There is no station teleport or physics reset. Service braking targets the next stop and advances the stop cursor once, after arrival. Fog and train use the same route metres. Arrival calls `enter_station`, never `reset`.

`RouteTrack` instances rails and sleepers in 120 m visibility chunks, with continuous collision terrain and telegraph poles. All three station scenes remain resident. Keeping this small world resident avoids unloading riders, containers or dropped supplies. Visibility culling limits distant track rendering; ordinary camera frustum culling handles station buildings. Larger 10–15-station expeditions should stream presentation/collision chunks around occupied areas while retaining authority state by ID.

The two new station scenes reuse `StationBuilding`, platform/ramp geometry, existing licensed materials, SearchContainer and item resources. Walls, open entrances, roofs, interiors and fog shelters share dimensions. These are functional modular environments, not a claim of photorealistic art. They are intended to accept the Milestone 2.6 art pass later.

## Pacing

Tuning lives in `resources/journey/harlow_escape.tres` and `escape_fog.tres`. Defaults: cruise 8 m/s; boiler 55 / 120; one coal sack adds 45; operation burns 0.32 units/s. Ideal travel burns roughly 171 units before acceleration/braking overhead, so starting reserves and the Harlow sack cannot finish the journey. Guaranteed caches prevent seed-dependent fuel softlocks.

The front starts 1,050 m behind Harlow, begins at 2.3 m/s, adds 0.08 m/s per minute and caps at 4.3 m/s before event/difficulty modifiers. Gentle and Severe apply 0.75 and 1.25 multipliers. Warnings, calm periods and seeded surges remain the existing fog system. Nominal train travel is about nine minutes; exploration, carrying, searching and learning controls are intended to bring a first run into the requested 20–40-minute range. This is a tuning target, not a measured novice playtest. The validation report distinguishes the fast automated route from the deliberately late Ashford escape.

## Save format and ownership

`JourneySave` writes JSON schema version 1 to `user://harlow_escape_v1.json`. It first validates a complete snapshot, writes a temporary file, flushes it and renames it over the previous save. Missing, malformed, oversized, incompatible-route or invalid-item saves leave the running world unchanged. Saves cannot execute code. Schema/content changes must bump the mission ID or version and supply a migration if backward compatibility is desired.

The snapshot includes route signature/segment, stop cursor, seed/difficulty, train state/speed/profile/progress, boiler fuel, exact backpack/storage slots, player pose/relative car offset/stamina/health, held and loose cargo, monotonic supply IDs, searched/depleted containers keyed by cache ID, stable door IDs, mission ledger, fog front/time/remainder, active/pending event and RNG state. Cached loot capacities are validated against the saved seed. IDs and RNG integers avoid JSON float precision loss where necessary.

There is one owner for supplies: container contents, backpack, train storage, or a WorldItem (held by a player or resting in the world). Restore replaces these owners rather than appending to them. Repeated Continue cannot duplicate supplies. The train and fog are held for six physics frames while saved transforms settle, then their saved motion resumes. Normal travel never uses this restoration path.

Save is available while grounded, including on a moving train and while holding heavy cargo. Active searches, jumps and attached climbing states require finishing the action or standing on a floor first; the UI explains this and leaves the previous save intact. There is one manual slot and no autosave. Camera orientation and open menu state are not persisted.

`MissionState` is a node-free ledger with explicit observations from successful supply collection, station arrivals, refueling and note interaction. Results have a versioned data shape without coins or rewards. `JourneyController` owns progression; presentation only reads it. For co-op, a server should own the itinerary, fixed fog ticks, train controls, station/cache ledger, mission ledger and inventory transactions. Clients submit interaction requests with player/entity IDs and render replicated state. The existing fog player registry permits multiple independent exposure components; the current save adapter still captures one local controllable player. Multiplayer transport, lobbies, rewards, upgrades and rescue NPCs are deliberately outside this milestone.

## Validation entry points

```sh
tools/run_tests.sh /path/to/Godot_v4.5.1
/path/to/godot --headless --path . --fixed-fps 60 tools/validate_journey.tscn
/path/to/godot --headless --path . --fixed-fps 60 tools/validate_journey.tscn -- --fuel-shortage
/path/to/godot --headless --path . --fixed-fps 60 tools/validate_journey.tscn -- --stranded
/path/to/godot --headless --path . --fixed-fps 60 --script res://tools/validate_resume.gd -- --phase=write
/path/to/godot --headless --path . --fixed-fps 60 --script res://tools/validate_resume.gd -- --phase=read
```

The continuous journey validator uses movement, aiming, E interactions and the real supply-ledger R action. It does not inject fuel, edit mission progress, reposition the train/player, or reset fog. `--late-escape` waits for the actual front in Ashford’s distant workshop, carries a machine component out under approaching fog, drops it using G, and runs back to the train. The separate process-resume fixture deliberately sets up a mid-route save and labels that setup; it is not the recorded journey.

The macOS pipeline retains Godot 4.5.1, universal export, Apple Silicon windowed/headless, Intel headless, fresh-download checks, bundle integrity and optional signing/notarization. It also runs the complete journey, natural fuel exhaustion/recovery, natural stationary-train fog catch and two-process resume checks. The test floor increases from 214 to 246. All original tests remain; two assertions naming the startup scene now expect the inherited mission scene. The original exported mechanics checks still run against their original sandbox, after the actual shipped mission has been loaded and validated.

See the finalization validation/performance report and PR #4 integration notes for evidence and remaining limits.
