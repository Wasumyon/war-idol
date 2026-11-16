# Main and the calendar — spec

Status: **approved and built** (placeholder content from Day 2 on). One departure: `first_shot` still records its own result through `Game.record_first_shot`, which keeps its save-retry screen. Project: root `game/`. Sources: the bible
(three acts, 40 days), canon 11, `outline.md`, `game_design.md`.

## 1. What exists in `game/` today

- Main scene `opener/opener.tscn` (cold-open shooter) → `vn.tscn` → `first_shot/first_shot.tscn`
  → `vn.tscn` (aftermath). Every handoff is `get_tree().change_scene_to_file()`:
  `opener.gd:83`, `vn.gd:1145`, `first_shot.gd:59`.
- `Game` autoload holds the save (`user://campaign.save`, atomic `_commit`), the chapter list
  (`scenes/00`–`04`), and the first-shot state (`first_shot_pending`, `_outcome`, `_receipt`).
  `Game.day` exists and is saved, but nothing ever changes it.
- When chapter 04 ends the VN prints "— end —" and stops. There is no hub.
- The runner was ported from `sandbox/slice/` into `game/minigames/runner/` (2026-11-16); `sandbox/slice/` is now frozen.

## 2. Day count: 40

Keep the bible's and canon 11's 40 days with a checkpoint every five. The count is data, not a
constant in code, so it can move.

- Acts by the bible's percentages: Act 1 = days 1–10, Act 2 = 11–30, Act 3 = 31–40. The EMP and
  capture (70–75%) land on days 28–30; the interrogation and fork on day 31.
- The outline has 34 beats on the calendar (07–40, plus Route B's epilogue; 01–06 are the prologue
  the written scenes already cover inside Day 1). Several share a day and the ice sequence (20–25)
  runs four days, which gives roughly 24–28 story days.
- That leaves about 12 fully free days, plus the open slot on story days that use only one. About
  half of the 80 slots are the player's. This is what "Hype is floor plus window" needs: story
  days supply the floor, free slots supply the window.
- 30 days would leave Act 2 with no free days; 50 would put more filler than story in Act 1.

Placement, by the beat numbers of the three-act `outline.md`:

| days | content |
|---|---|
| 1 | Opening as written: cold open, prologue, intro, first stream, first shot, aftermath (beats 01–10). No hub. |
| 2–4 | Aysel at Keno's (11), Watcher 6 interview (12), the red flag (13), free slots |
| 5 | Checkpoint. Kathay's banned stream in the evening (14, canon 11); Ottenok's leak (15) |
| 6–10 | Investigation offers; Day 7 Kathay at the LZ (16, canon 11); free days; checkpoint at 10 closes Act 1 |
| 11–15 | Albrecht's rescue (17); Ottenok's trap and death (18–19); free days |
| 16–19 | Ice sequence (20–25): hub locked, four scripted days |
| 20–27 | Crew reorganised (26), gala and the hardware (27–28), vendetta (29), the bait (30), free days |
| 28–30 | EMP, the visor falls, captured (31–33) |
| 31 | Interrogation and the fork (34). Route B: epilogue (B1), calendar ends here |
| 32–40 | Route A: breakout (35), inadmissible truth (36), assembly (37), heist (38), escape (39), broadcast (40) |

The ending stays open: days 31–40 are placeholders gated on a `route` flag, and the calendar
does not assume Model A or Model B.

## 3. Data model

One data file, `game/calendar/calendar_data.gd`, validated at startup in debug builds.

**Segment** — one playable thing.

| field | meaning |
|---|---|
| `id` | unique string, e.g. `d02_aysel_bar` |
| `type` | `vn` or `minigame` (the runner and tunnel are later `minigame` scenes) |
| `source` | `vn`: a `scenes/*.txt` path and optional label. `minigame`: a scene path |
| `args` | passed to the segment, e.g. `{route = "hard"}` |
| `requires` | `flags_all`, `flags_none`, `min_day`, `max_day`. Stat gates are left out until the dials task |
| `once` | true for anything that must not repeat |
| `outputs` | flags, followers, money and stat deltas applied on completion; a minigame's result can select among output sets (`capture` / `miss`) |

**Day** — two slots, `day` and `evening`. A day with no entry in the file is a free day.

| field | meaning |
|---|---|
| `day` | number |
| `slots` | per slot: a list of segments played in order (scripted), or absent (free) |
| `skip_hub` | go straight into the segments (Day 1, the ice sequence, captivity) |
| `requires` / `fallback` | a gated story day names the shared fallback it plays when locked |

**Offer pool** — segments with no fixed day. In a free slot the hub lists every offer whose
`requires` passes. Runner routes (easy / medium / hard), interviews and evening scenes live here.

**Saved state added to `Game`** (save version 2, with version 1 saves migrated): `slot`,
`active_segment`, `done_segments`. One new call, `complete_segment(id, result)`, applies the
outputs and advances slot and day in a single `_commit`, so a payout can never apply twice.
The dials and `lane_x()` are untouched.

## 4. Main layers

`game/main/main.tscn`, set as the main scene.

| node | role |
|---|---|
| `World` (Node) | one child at a time: the hub or a minigame |
| `Story` (CanvasLayer) | the `vn.tscn` instance while a VN segment runs |
| `HUD` (CanvasLayer) | only what the fiction holds an instrument for: the phone. No meters |
| `Pause` (CanvasLayer, always processing) | Esc: resume, quit |
| `Transition` (CanvasLayer) | fade out, swap the child, fade in; blocks input meanwhile |
| `Debug` (CanvasLayer, debug builds only) | day, slot, flags; jump to day; set flag; skip segment |

**The hub** is its own scene (`game/hub/hub.tscn`) behind one signal, `segment_chosen(id)`. This
build makes it a flat placeholder: Missions (today's offers for the current slot), Calendar (the
40-day grid with today and the checkpoints), Menu (opens Pause), and Dossiers and News/Stats as
stubs that open an empty panel. Whether the final room is 3D with 2D characters is decided inside
that scene later and changes nothing outside it.

## 5. Control flow

Every segment root has `signal finished(result: Dictionary)` and `func begin(args)`.

1. Boot: `Main` asks the calendar what is next: the `active_segment` to resume, a scripted
   segment on a `skip_hub` day, or the hub.
2. Hub: the player picks an offer. On a scripted slot Missions shows the one mandatory item.
3. `Transition` swaps the hub out and the segment in; `active_segment` is saved.
4. The segment plays and emits `finished(result)`. It does not change scene or advance the day.
5. `Main` calls `Game.complete_segment`, then goes to step 1. After the evening slot the day
   advances; after the last day an ending placeholder shows.

Changes to existing scenes:
- `opener.gd`, `first_shot.gd`: drop `change_scene_to_file`, emit `finished`.
- `vn.gd`: emit `call_requested("first_shot")` instead of changing scene, and `finished` where
  it now shows "— end —". It still walks chapters 00–04 for Day 1.
- Day 1 is `[opener, opening VN]`; the VN's `first_shot` call makes `Main` swap in
  `first_shot` and feed the result to the existing `Game.record_first_shot`.
- `tests/first_shot_campaign.gd` opens scenes with `change_scene_to_file` and will be rewritten
  to drive `Main`.

**Runner slot:** a `minigame` segment whose scene will be `res://minigames/runner/runner.tscn`, taking
`{route, zone}` and returning `{footage, damage}`. Until it is ported, runner offers point at a
placeholder scene with two buttons (good run / bad run).

## 6. Build steps (commit before each)

1. `Game`: save version 2, `slot`, `active_segment`, `done_segments`, `complete_segment`.
2. Calendar data and reader, with placeholder days 2–4: one VN day, one minigame day, one free day.
3. `Main` with the six layers and the Transition swap; convert the three handoffs.
4. Hub placeholder, Pause, Debug.
5. Rewrite the campaign test; run with a clean debug output.
6. Rewrite `CLAUDE.md` for the `game/` structure.

## 7. Open points

- **Kathay on Day 7** is gated on two investigation segments (canon 11), but she is needed later.
  The spec assumes a fallback that still introduces her, worth less.
- **Free slots after the evening:** canon 11's loop has a shop between mission and evening. The
  shop is not in this build; it would be a hub hotspot, not a slot.
- **Checkpoints every five days:** assumed to mean a story gate on days 5, 10, … and a save the
  player can return to. Only the story gate is built now.
