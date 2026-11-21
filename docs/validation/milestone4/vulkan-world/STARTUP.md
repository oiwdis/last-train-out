## Cold startup and initial gameplay

| Hosted Mac | First camera | Playable / attempts | Median engine time at mission ready (s) | First 30 frames, maximum across completed processes (ms) |
|---|---|---:|---:|---:|
| Forward | Origin | 4 / 8 | 30.55 | 310.33 |
| Forward | Platform | 8 / 8 | 24.17 | 103.49 |
| Reverse | Origin | 8 / 8 | 18.40 | 55.21 |
| Reverse | Platform | 8 / 8 | 18.29 | 120.12 |

The ready timestamp uses Godot’s clock since engine startup. These direct diagnostic runs do not supply an external launcher epoch. Process wall time includes the final frame probe and shutdown. Every attempted process has a row. A process that lost its device has no playable time or initial-frame measurement. The successful origin starts are a selected subset on hosts that reproduced the failure. The first process on each host also encounters a colder shared driver cache. [Complete attempts, elapsed time, RSS and first 30 frames](player-times.csv)
