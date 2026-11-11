# Recorded successful routes

These are constructed solutions measured in Godot 4.7.2 on macOS. X coordinates are pixels relative to the centre of the foundation; preview positions are clamped to [-100,100]. Drop with fixed orientations and wait for settling after every action. The treasure slots are 2, 4, 6. All other slots are ordinary pieces.

For each route below, **all six** extraction orders succeeded: 1-2-3, 1-3-2, 2-1-3, 2-3-1, 3-1-2, 3-2-1. Full settled body transforms after each placement are in `evidence/physics-verification.json`.

| Shift | Name | Drop X positions, pieces 1–8 | Successful extraction orders |
|---|---|---|---|
| 01 | First salvage | 0, 0, 0, 0, 0, 0, 0, 0 | 6 / 6 |
| 02 | Make room | 0, -18, 0, 18, 0, 0, 0, 0 | 6 / 6 |
| 03 | Bridge the gap | 0, 26, 0, -26, 0, 0, 0, 0 | 6 / 6 |
| 04 | Left luggage | 0, -63, 0, 28, 0, -22, 0, 0 | 6 / 6 |
| 05 | Offset thinking | 0, 36, 0, -72, 0, 30, 0, 0 | 6 / 6 |
| 06 | Small margins | 0, -63, 0, 38, 0, -63, 0, 0 | 6 / 6 |
| 07 | Cross purposes | 0, 72, 0, -30, 0, 62, 0, 0 | 6 / 6 |
| 08 | Heavy little things | 0, -34, 0, 64, 0, -72, 0, 0 | 6 / 6 |
| 09 | Side by side | 0, 64, 0, -72, 0, 24, 0, 0 | 6 / 6 |
| 10 | Narrow escape | 0, -72, 0, 61, 0, -59, 0, 0 | 6 / 6 |
| 11 | Overhang | 0, 68, 0, 66, 0, -72, 0, 0 | 6 / 6 |
| 12 | The last shift | 0, -72, 0, 64, 0, -72, 0, 0 | 6 / 6 |

## Strategy probes

The first three shifts use enclosed bridges. Later shifts mix offset bridges, one-sided brackets and central-stem cantilevers, with changing cap shapes and clearances. Treasures must fit the particular load path; copying one central pile is unreliable.

| Shift | All pieces centred, then remove 3-2-1 |
|---|---|
| 01 | won |
| 02 | build loss |
| 03 | build loss |
| 04 | build loss |
| 05 | build loss |
| 06 | timeout |
| 07 | build loss |
| 08 | won |
| 09 | timeout |
| 10 | won |
| 11 | timeout |
| 12 | timeout |

A test `timeout` means the harness stopped waiting after 20 simulated seconds, not that the game imposes a timed loss. The game continues to simulate and offers Restore checkpoint/Retry through Pause. Such unsettled layouts remain a playtest concern.

Top-to-bottom extraction succeeded on every authored solution; all other orders also succeeded on these intentionally supported arrangements. Separating treasure from the final structural load path is a strong solution strategy. That is consistent with the objective, but **extraction-order depth and long-term difficulty are not validated**. These samples demonstrate successful construction planning, not that the game is equally interesting across all strategies. Observe human repeat attempts before claiming the collection is balanced or adding more levels.
