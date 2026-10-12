# Melody note byte values

The melody is stored in three parallel tables in `music.s`: `note_lo` holds
the low byte of each pulse-channel timer, `note_hi` holds its high bits, and
`note_durations` holds the length in video frames. The same table index refers
to the same note in all three tables.

The pulse timer is formed as
`note_lo + ((note_hi & $07) << 8)`. With the current `note_hi` values all zero,
the timer is just the `note_lo` byte.

| Index | `note_lo` byte | `note_hi` byte | Timer | Approx. pitch | Comment |
|---:|---:|---:|---:|---:|---|---|
| 0 | `$FE` | `$00` | 254 | 439.1 Hz | A4 |
| 1 | `$D5` | `$00` | 213 | 522.1 Hz | C5 |
| 2 | `$BE` | `$00` | 190 | 586.2 Hz | D5 |
| 3 | `$9F` | `$00` | 159 | 699.1 Hz | F5 |
| 4 | `$FE` | `$00` | 254 | 439.1 Hz | A4 |
| 5 | `$00` | `$00` | Rest | Silence | Rest |

At approximately 60 video frames per second, 18 frames is about 0.3 seconds
and 36 frames is about 0.6 seconds. The durations, in table order, are 18, 18,
18, 36, 18, and 18 frames. Entry 5 is a rest because a zero `note_lo` value
disables the pulse channel; its timer does not produce a note.
