# Fog balancing, first playable pass

These values remain the original Harlow sandbox preset. The shipped three-station mission uses `resources/journey/escape_fog.tres` and a seed/difficulty menu; see [current journey pacing](MILESTONE3_JOURNEY.md#pacing).

All values live in `resources/fog/standard.tres` / `scripts/fog/fog_config.gd`; each run duplicates its resource. Presets do not change them. `scenario_seed` is exported on FogSystem. Difficulty is a tuning multiplier, not a new options menu.

| Setting | Standard | Reason |
|---|---:|---|
| Initial clearance | 210 m | Learn controls, inspect several caches, then make choices |
| Base speed | 0.8 m/s | An unladen survivor can retreat; a stopped train cannot wait indefinitely |
| Escalation | +0.08 m/s/min, cap 1.6 | Early orientation time, sustained pressure later |
| Approach / critical | 130 / 45 m | Warn before a return from the far warehouse becomes dangerous |
| Station approach | 0.85x within final 55 m | Slight grace without stopping the front |
| Events | 50–85 s apart, 10 s warning, 16 s active | Readable changes with reproducible spacing |
| Surge / calm | 1.8x / 0.55x | Time-limited changes; maximum standard surge 2.88 m/s |
| Exposure | 3 units/s, up to 3x with depth | A boundary crossing is survivable; deep lingering is not |
| Damage grace / base | 15 dose / 5 HP/s | Several seconds to react before damage, increasing thereafter |
| Recovery | 5 dose/s in clear air | A short escape produces a meaningful recovery interval |
| Protection | cab .72 / crew .48 / building .25 / open deck .12 | Shelter buys time, never indefinite survival |
| Boiler | 75 initial / 120 capacity / .65 per moving second | ~115 s of initial movement; zero idle burn while scavenging |
| Stored coal sack | +45 fuel | Heavy supplies buy about 69 additional moving seconds |

Ignoring events, the standard front reaches Harlow's stop in roughly four minutes, with the critical phase allowing roughly 45 seconds at early speeds. Exact arrival varies with escalation, difficulty and warned events. UI shows rounded route clearance rather than a deceptively exact countdown. The API also exposes a conservative time estimate using maximum surge speed.

Harlow's far warehouse is about 80 m ahead of the train. This makes the **return route** more urgent than the player's immediate location. Existing 2.5 m/s heavy carrying and free-hand vault/ladder requirements create the risk naturally. Cargo can be abandoned and recovered; fog never deletes supplies or ends a search by timer.

Lower/higher difficulty can start at 0.8/1.3 respectively; it scales speed and dose, with no instant damage spike or random front jump. Tune initial distance per mission. Closed doors matter: baseline train doors start open, so shelter initially provides only building-level protection. Health does not regenerate when exposure clears.

This is an initial engineering balance, not a human playtest claim. The gameplay validation script uses explicit setup/time cuts to exercise late danger in a short recording. The uninterrupted Warehouse B return then uses real movement, vaults, ladder boarding and the cab regulator. The finite baseline line eventually ends; fog continues and a stopped train remains vulnerable. A second playable stop is pending route/world progression work.
