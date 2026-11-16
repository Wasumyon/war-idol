# War Idol — project context

Read this first. Keep it under a page; detail lives in the files it points to.

## The game
A hard-boiled sci-fi visual novel set on Io, Jupiter's volcanic moon. A broke, one-legged veteran
partners with a VTuber covering the war for money. Choices flag special events and lead to two
endings. Between story scenes there is a runner: a 5-lane infinite runner (Nikke-like) where you
film dangerous events with the cursor (Pokémon Snap-like). The twist: the AR visors render ordinary
human colonists as monsters.

## Engine
Godot **4.7.x**, GDScript, Forward Plus, 960×540. The project is `car/project.godot` (to be renamed
`game/`). One autoload: `Game` (`car/autoload/game.gd`) — stats, flags, chapter, player name.

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
| `car/vn/scenes/NN_*.txt` | the written scenes (plain text, run by `car/vn/vn.tscn`) |
| `car/slice/` | the runner prototype — **sandbox**, AI-written |
| `car/wip/`, `car/test*.tscn` | older car-physics tests — sandbox |
| `tunnel/` | **game-jam piece** (Tunnel Escape): separate Godot project, short stealth/light-puzzle walk in 5 chambers. Design doc: Google Doc "War Idol Tunnel Escape". Ported from another universe; re-theme to War Idols |
| `_archive/` | superseded docs — do not use as reference |

## Rules
- **Every fact lives in one file. The bible wins any conflict**; fix canon or the outline to match.
- Canon changes as the story is written. Record decisions; don't infer them from old drafts.
- `slice/` and `vn/` are prototypes. Nothing in them is merged into the real game as-is: a
  mechanic that works gets written up as a spec and reimplemented.
- Sandbox code may use the core; **core code never references the sandbox.**
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
- Restructure `outline.md` to the bible's three acts (add Albrecht's rescue, the capture, the
  interrogation; fix Beat 14 and Beat 22 for Kathay).
- Folder reorganisation and the `MainGame` scene (World / Story / HUD / Pause / Transition /
  Debug layers).
- Update `Game` stats to match `vn_game_design.md` (the dials), and move `lane_x()` out of it.
