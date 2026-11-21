## Cold startup and initial gameplay

| Hosted Mac | First camera | Playable / attempts | Median engine time at mission ready (s) | First 30 frames, maximum across completed processes (ms) |
|---|---|---:|---:|---:|
| Forward | Origin | 14 / 16 | 18.00 | 617.56 |
| Forward | Platform | 16 / 16 | 18.10 | 56.67 |
| Reverse | Origin | 7 / 16 | 21.14 | 89.93 |
| Reverse | Platform | 16 / 16 | 23.10 | 285.68 |

The ready timestamp uses Godot’s clock since engine startup. These direct diagnostic runs do not supply an external launcher epoch. Process wall time includes the final frame probe and shutdown. Every attempted process has a row. A process that lost its device has no playable time or initial-frame measurement. The successful origin starts are a selected subset on hosts that reproduced the failure. The first process on each host also encounters a colder shared driver cache. [Complete attempts, elapsed time, RSS and first 30 frames](player-times.csv)
