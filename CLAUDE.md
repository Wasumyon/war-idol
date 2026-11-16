# War Idol — project context

Read this first. Keep it under a page; detail lives in the files it points to.

## The game
A hard-boiled sci-fi visual novel set on Io, Jupiter's volcanic moon. A broke, one-legged veteran
partners with a VTuber covering the war for money. Choices flag special events and lead to two
endings. Between story scenes there is a runner: a 5-lane infinite runner (Nikke-like) where you
film dangerous events with the cursor (Pokémon Snap-like). The twist: the AR visors render ordinary
human colonists as monsters.

## Engine
Godot **4.7.x**, GDScript, Forward Plus, 960×540. **The game is the root `vn/` project**
(`vn/project.godot`). `car/` is the old sandbox project and `tunnel/` is a separate one.

- Main scene: `vn/main/main_game.tscn` (**MainGame**), the one persistent scene. Layers: World /
  Story / HUD / Pause / Transition / Debug (F3 in debug builds).
- One autoload: `Game` (`vn/autoload/game.gd`) — the save (`user://campaign.save`), stats, flags,
  chapter, player name, and the calendar position (day, slot, segment in play).
- **The calendar drives the game.** A day has two slots (day, evening). A slot is scripted (fixed
  segments) or free (the player picks an offer in the hub). Data: `vn/calendar/calendar_data.gd`.
- **A segment** is a VN scene or a minigame. Its root emits `finished(result)` and never changes
  scene or advances the day; MainGame swaps it through the Transition layer and saves.
- Test: `godot --headless --path vn res://tests/first_shot_campaign.tscn` (must print 0 failures).

## Where things are
| path | what |
|---|---|
| `io_story_bible.md` | **the big picture and the source of truth** — premise, twist, characters, Albrecht, acts, endings |
| `canon.md` → `canon/NN_*.md` | detailed rulings a scene must obey, one topic per file ("canon §4" = `canon/04_narrator.md`) |
| `outline.md` | the beats in order |
| `claude/decisions.md` (Claude Project, not the repo) | settled decisions not yet applied to their home files; "Still open" is the to-do list |
| `style_guide.md` | how to write: tense, voice, register, engine syntax |
| `vn_game_design.md` | tracked state: Hype, the dials, flags, ending models |
| `punchlist.md`, `01_intro_punchlist.md` | open errors and considerations |
| `maingame_spec.md` | MainGame, the calendar data model, the draft 40-day placement |
| `dossier_spec.md` | the in-game files: entry format, unlocks, pre/post-reveal versions, glitched text |
| `stealth_spec.md` | the stealth minigame (story beats and the on-foot job): rules, party, segment contract, build steps |
| `HANDOVER.md` | the opening slice: direction and build order |
| `vn/scenes/NN_*.txt` | the written scenes the game runs (plain text, played by `vn/vn.tscn`) |
| `vn/scenes/placeholder/` | stand-in scenes for calendar days not yet written |
| `vn/main/`, `vn/hub/`, `vn/calendar/` | MainGame and its layers, the hub (placeholder layout), the calendar |
| `vn/opener/`, `vn/first_shot/`, `vn/phone/` | Day 1's cold open and filming request; the phone |
| `vn/runner/` | the runner: `runner_segment.tscn` wraps the ported prototype (`slice.tscn`, R restarts, Enter ends with `{outcome, followers, money}`); `runner_placeholder.*` is the old stand-in, now unused |
| `car/vn/` | the older copy of the VN and its drafts — superseded by `vn/` |
| `car/slice/` | the runner prototype — **sandbox**; copied into `vn/runner/` (ported 2026-11-16), now frozen — edit `vn/runner/` |
| `car/wip/`, `car/test*.tscn` | older car-physics tests — sandbox |
| `tunnel/` | **game-jam piece** (Tunnel Escape): separate Godot project, short stealth/light-puzzle walk in 5 chambers. Design doc: Google Doc "War Idol Tunnel Escape". Ported from another universe; re-theme to War Idols |
| `_archive/` | superseded docs — do not use as reference |

## Rules
- **Every fact lives in one file. The bible wins any conflict**; fix canon or the outline to match.
- Canon changes as the story is written. Record decisions; don't infer them from old drafts.
- `car/` is the sandbox, a separate Godot project. Sandbox code may use the core; **core code
  (`vn/`) never references the sandbox (`car/`)**, so anything the game needs is copied into `vn/`.
- New playable content is a segment listed in `calendar_data.gd`. Never call
  `change_scene_to_file` in `vn/`.
- Files starting `_` are drafts or generated reading copies (`_read_*.txt`). Don't edit them or
  use them as source.
- Move files only inside Godot's FileSystem dock, and commit to git before each step.

## Working with Claude
- **Load only what the task needs:** this file, the bible, the one or two canon files involved,
  then the task and the files it touches. Never send drafts, `_read_` copies, art or `.import` files.
- Ask for diffs or changed functions, not whole files.
- One task per chat.
- **Opus:** story decisions, canon and outline work, line edits against the style guide,
  architecture, specs. **Sonnet:** file moves, path fixes, building from a spec, tool scripts,
  mechanical punchlist items.

## In progress
- **Game jam (about a week, from 2026-10-24):** build `tunnel/` (own project, never references `car/`).
- `outline.md` is in the bible's three acts (2026-11-15). Its *proposed* beats and punchlist
  B10–B14 wait on a yes before scenes are written against them.
- Fill the calendar: days 2–40 are placeholders, placed by `maingame_spec.md` §2.
- Runner: ported into `vn/runner/` behind the segment contract (2026-11-16), a straight copy, not playtested in a window. Next: playtest, then hook its followers/money into the outcome payouts (the calendar currently pays fixed per-outcome amounts).
- The hub's real room (3D bunker, characters possibly 2D); News/Stats is a stub.
- Dossiers: specced in `dossier_spec.md` (2026-11-15), not built; its §9 story points are open.
- Stealth minigame: specced in `stealth_spec.md` (2026-11-15), not built; its §10 points are open.
- Update `Game` stats to match `vn_game_design.md` (the dials), and move `lane_x()` out of it.
