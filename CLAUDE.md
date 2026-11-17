# War Idol — project context

The map of the project. Read `AGENTS.md` first, then this, then `STATUS.md`. Keep it under a page; detail lives in the files it points to.

## The game
A hard-boiled sci-fi visual novel set on Io, Jupiter's volcanic moon. A broke, one-legged veteran
partners with a VTuber covering the war for money. Choices flag special events and lead to two
endings. Between story scenes there is a runner: a 5-lane infinite runner (Nikke-like) where you
film dangerous events with the cursor (Pokémon Snap-like). The twist: the AR visors render ordinary
human colonists as monsters.

## Engine
Godot **4.7.x**, GDScript, Forward Plus, 960×540. **The game is the root `game/` project**
(`game/project.godot`). `sandbox/` holds the old prototypes (frozen). `tunnel/` is what is left of the Tunnel Escape jam project, mid-port.

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
| `docs/chaac_run_spec.md` | Day 1's opening run (replaces the opener): beats, mechanics, build order, title menu and name entry |
| `docs/tickets/` | jobs Claude hands to the builders, one file each (`TEMPLATE.md`) |
| `docs/story_inbox.md` | story ideas noted mid-build, waiting to be sorted |
| `docs/` | every design doc: bible, canon, outline, specs, punchlists, `game_design.md`, the design-doc `.docx`, `stories/`, `boundarypush/` |
| `source_art/` | unshipped art and prompts (characters, backgrounds, enemy models, concept art, UI base, raw sources, review thumbnails, source music). Not part of any Godot project |
| `docs/tunnel_port_plan.md`, `docs/tunnel/` | the tunnel port: plan, steps and inventory; the jam project's own design docs |
| `tools/` | scripts: `run_tests.ps1`, `stale_names.ps1` (fails the tests if a retired name comes back), `commission.ps1`, `make_plain.ps1`, `make_flatline.ps1`, `stale_dossiers.ps1`; `tools/tunnel/` holds the jam project's generators, archived as they were (they do not run from there) |
| `game/story/` | the VN: player `vn.tscn`/`vn.gd` (+ `inline_marks.gd`, `script_effect.gd`), `scenes/NN_*.txt` (the written scenes, plain text), `scenes/placeholder/` (stand-ins for unwritten calendar days), and Day 1's `opener/` and `first_shot/` |
| `game/main/` | **Main** (`main.tscn`, the conductor: layers, segment swap, save) and `transition.gd` |
| `game/ui/` | the overlay layers' scripts: `phone.gd`, `pause.gd`, `debug.gd` |
| `game/hub/`, `game/calendar/`, `game/dossier/` | the hub (placeholder layout), the calendar, the files screen (`entries/<id>.txt`; a scene line's `@ file <id>` files one) |
| `game/autoload/` | `GameState` (`game_state.gd`), the only autoload |
| `game/minigames/runner/` | the runner: `runner_segment.tscn` wraps the ported prototype (`run.tscn`/`run.gd` is the run itself, `player_craft.gd` the player's vehicle; R restarts, Enter ends with `{outcome, followers, money}`) |
| `game/minigames/stealth/` | the stealth minigame (`stealth.tscn` is the segment root) |
| `game/minigames/tunnel/` | Tunnel Escape, mid-port: files moved and paths repointed, **not yet a segment and not playable** (no segment root; its tests are parked in `tests/` there and do not run). Follow `docs/tunnel_port_plan.md` |
| `game/assets/` | shared `img/` and `sfx/` (feature-specific art stays in its feature's folder) |
| `game/tests/` | headless tests, run by `tools/run_tests.ps1` |
| `sandbox/vn/` | the older copy of the VN and its drafts — superseded by `game/story/` |
| `sandbox/slice/` | the old runner prototype; copied into `game/minigames/runner/` (ported 2026-11-16), now frozen — edit `game/minigames/runner/` |
| `sandbox/wip/`, `sandbox/test*.tscn` | older car-physics tests, frozen |
| `tunnel/` | leftovers of **Tunnel Escape**, a minigame of this game (an escape sequence, like the one in Danganronpa 3; a short stealth/light-puzzle walk in 5 chambers), built for a game jam as its own Godot project. Its files have moved out; what remains is `project.godot`, the icon, a nested git repo and git-ignored files (`build/`, `_tools/`, `mainguy.*`). It no longer runs on its own and is deleted at the port's last step. Design doc: Google Doc "War Idol Tunnel Escape" |
| `_archive/` | superseded docs — do not use as reference |

## Rules
- **Every fact lives in one file. The bible wins any conflict**; fix canon or the outline to match.
- Canon changes as the story is written. Record decisions; don't infer them from old drafts.
- **All work is built directly in `game/`**, whoever or whatever writes it. `sandbox/` is the old
  prototype project, frozen. It is a separate Godot project, so `game/` cannot load its files:
  copy anything the game needs into `game/`.
- New playable content is a segment listed in `calendar_data.gd`. Never call
  `change_scene_to_file` in `game/`.
- Files starting `_` are drafts or generated reading copies (`_read_*.txt`). Don't edit them or
  use them as source.
- Inside `game/`, move files in the FileSystem dock, or on disk with Godot closed (then run `godot --headless --path game --import` and `tools/run_tests.ps1`); elsewhere (`docs/`, `source_art/`, `tools/`) use `git mv`. Commit to git before each step.

## Working here
How agents work, who does what, tickets, git and hand-off: **`AGENTS.md`**.
What is being worked on now: **`STATUS.md`** (this file no longer carries status).
