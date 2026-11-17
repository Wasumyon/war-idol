# War Idol — project context

Read this first. Keep it under a page; detail lives in the files it points to.

## The game
A hard-boiled sci-fi visual novel set on Io, Jupiter's volcanic moon. A broke, one-legged veteran
partners with a VTuber covering the war for money. Choices flag special events and lead to two
endings. Between story scenes there is a runner: a 5-lane infinite runner (Nikke-like) where you
film dangerous events with the cursor (Pokémon Snap-like). The twist: the AR visors render ordinary
human colonists as monsters.

## Engine
Godot **4.7.x**, GDScript, Forward Plus, 960×540. **The game is the root `game/` project**
(`game/project.godot`). `sandbox/` is the old sandbox project and `tunnel/` is a separate one.

- Main scene: `game/main/main.tscn` (**Main**), the one persistent scene. Layers: World /
  Story / HUD / Pause / Dossier (the files, an overlay, not a segment) / Transition / Debug.
- **Debug builds:** F3 opens the debug panel; F4 files every dossier entry; F5 toggles the visor
  reveal. A new key is one `_hotkey()` line in `game/ui/debug.gd` plus a `debug_*` function on
  Main; the panel lists them all. F6–F11 are free.
- One autoload: `GameState` (`game/autoload/game_state.gd`) — the save (`user://campaign.save`), stats, flags,
  chapter, player name, and the calendar position (day, slot, segment in play).
- **The calendar drives the game.** A day has two slots (day, evening). A slot is scripted (fixed
  segments) or free (the player picks an offer in the hub). Data: `game/calendar/calendar_data.gd`.
- **A segment** is a VN scene or a minigame. Its root emits `finished(result)` and never changes
  scene or advances the day; Main swaps it through the Transition layer and saves.
- Test: `powershell -File tools/run_tests.ps1` runs every headless test in `game/tests/` (must say 0 failed).

## Where things are
| path | what |
|---|---|
| `docs/io_story_bible.md` | **the big picture and the source of truth** — premise, twist, characters, Albrecht, acts, endings |
| `docs/canon.md` → `docs/canon/NN_*.md` | detailed rulings a scene must obey, one topic per file ("canon §4" = `docs/canon/04_narrator.md`) |
| `docs/outline.md` | the beats in order |
| `claude/decisions.md` (Claude Project, not the repo) | settled decisions not yet applied to their home files; "Still open" is the to-do list |
| `docs/style_guide.md` | how to write: tense, voice, register, engine syntax |
| `docs/game_design.md` | tracked state: Hype, the dials, flags, ending models |
| `docs/punchlist.md`, `docs/01_intro_punchlist.md` | open errors and considerations |
| `docs/main_spec.md` | Main, the calendar data model, the draft 40-day placement |
| `docs/dossier_spec.md` | the in-game files: entry format, unlocks, pre/post-reveal versions, glitched text |
| `docs/stealth_spec.md` | the stealth minigame (story beats and the on-foot job): rules, party, segment contract, build steps |
| `HANDOVER.md` | the opening slice: direction and build order |
| `docs/` | every design doc: bible, canon, outline, specs, punchlists, `game_design.md`, `restructure_plan.md`, the design-doc `.docx`, `stories/`, `boundarypush/` |
| `source_art/` | unshipped art and prompts (characters, backgrounds, enemy models, concept art, UI base, raw sources, review thumbnails, source music). Not part of any Godot project |
| `tools/` | scripts: `run_tests.ps1`, `commission.ps1`, `make_plain.ps1`, `make_flatline.ps1`, `stale_dossiers.ps1` |
| `game/story/` | the VN: player `vn.tscn`/`vn.gd` (+ `inline_marks.gd`, `script_effect.gd`), `scenes/NN_*.txt` (the written scenes, plain text), `scenes/placeholder/` (stand-ins for unwritten calendar days), and Day 1's `opener/` and `first_shot/` |
| `game/main/` | **Main** (`main.tscn`, the conductor: layers, segment swap, save) and `transition.gd` |
| `game/ui/` | the overlay layers' scripts: `phone.gd`, `pause.gd`, `debug.gd` |
| `game/hub/`, `game/calendar/`, `game/dossier/` | the hub (placeholder layout), the calendar, the files screen (`entries/<id>.txt`; a scene line's `@ file <id>` files one) |
| `game/autoload/` | `GameState` (`game_state.gd`), the only autoload |
| `game/minigames/runner/` | the runner: `runner_segment.tscn` wraps the ported prototype (`run.tscn`/`run.gd` is the run itself, `player_craft.gd` the player's vehicle; R restarts, Enter ends with `{outcome, followers, money}`) |
| `game/minigames/stealth/` | the stealth minigame (`stealth.tscn` is the segment root) |
| `game/assets/` | shared `img/` and `sfx/` (feature-specific art stays in its feature's folder) |
| `game/tests/` | headless tests, run by `tools/run_tests.ps1` |
| `sandbox/vn/` | the older copy of the VN and its drafts — superseded by `game/story/` |
| `sandbox/slice/` | the runner prototype — **sandbox**; copied into `game/minigames/runner/` (ported 2026-11-16), now frozen — edit `game/minigames/runner/` |
| `sandbox/wip/`, `sandbox/test*.tscn` | older car-physics tests — sandbox |
| `tunnel/` | **Tunnel Escape**, a minigame of this game (an escape sequence, like the one in Danganronpa 3), built quickly for a game jam: for now a separate Godot project, short stealth/light-puzzle walk in 5 chambers. Design doc: Google Doc "War Idol Tunnel Escape". Later it is ported into `game/minigames/tunnel/` as a segment (copy, repoint paths, wrapper), like the runner |
| `_archive/` | superseded docs — do not use as reference |

## Rules
- **Every fact lives in one file. The bible wins any conflict**; fix canon or the outline to match.
- Canon changes as the story is written. Record decisions; don't infer them from old drafts.
- `sandbox/` is the sandbox, a separate Godot project. Sandbox code may use the core; **core code
  (`game/`) never references the sandbox (`sandbox/`)**, so anything the game needs is copied into `game/`.
- New playable content is a segment listed in `calendar_data.gd`. Never call
  `change_scene_to_file` in `game/`.
- Files starting `_` are drafts or generated reading copies (`_read_*.txt`). Don't edit them or
  use them as source.
- Inside `game/`, move files in the FileSystem dock, or on disk with Godot closed (then run `godot --headless --path game --import` and `tools/run_tests.ps1`); elsewhere (`docs/`, `source_art/`, `tools/`) use `git mv`. Commit to git before each step.

## Working with Claude
- **Load only what the task needs:** this file, the bible, the one or two canon files involved,
  then the task and the files it touches. Never send drafts, `_read_` copies, art or `.import` files.
- Ask for diffs or changed functions, not whole files.
- One task per chat.
- **Opus:** story decisions, canon and outline work, line edits against the style guide,
  architecture, specs. **Sonnet:** file moves, path fixes, building from a spec, tool scripts,
  mechanical punchlist items.

## In progress
- **Restructure** (done 2026-11-16, `docs/restructure_plan.md`): `car/` → `sandbox/`, `vn/` → `game/`, `MainGame` → `Main`, autoload `Game` → `GameState`, `scenes/` etc. regrouped under `story/`, `minigames/`, `assets/`, `ui/`; docs in `docs/`, art in `source_art/`. **Old names are retired** (`car/`, `vn/` as the project folder, `MainGame`, `Game.`, `maingame_spec.md`, `vn_game_design.md`); if you see them, they are stale. Runner internals renamed too: `slice.*` → `run.*`, `runner.gd` → `player_craft.gd`, node/group `Runner`/`runner` → `Player`/`player`, `runner_placeholder.*` deleted.
- **Game jam (about a week, from 2026-10-24):** build `tunnel/` (own project, never references `sandbox/`).
- `docs/outline.md` is in the bible's three acts (2026-11-15). Its *proposed* beats and punchlist
  B10–B14 wait on a yes before scenes are written against them.
- Fill the calendar: days 2–40 are placeholders, placed by `docs/main_spec.md` §2.
- Runner: ported into `game/minigames/runner/` behind the segment contract (2026-11-16), a straight copy, not playtested in a window. Next: playtest, then hook its followers/money into the outcome payouts (the calendar currently pays fixed per-outcome amounts).
- The hub's real room (3D bunker, characters possibly 2D); News/Stats is a stub.
- Dossiers: built from `docs/dossier_spec.md` (merged 2026-11-16), four placeholder entries, no
  `@ file` in any scene yet. Next: settle its §9 story points, then write entries (Opus) and file them in scenes.
- Stealth minigame: specced in `docs/stealth_spec.md` (2026-11-15); build steps 1–3 are in (map, guards and detection, noise and concealment); its §10 points are open.
- Update `GameState` stats to match `docs/game_design.md` (the dials), and move `lane_x()` out of it.
