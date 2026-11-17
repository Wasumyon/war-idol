# Tunnel port plan

Move Tunnel Escape from its own project (`tunnel/`) into the game as a segment at
`game/minigames/tunnel/`, then delete `tunnel/`. One step per chat; commit after each step.

**Done means:** the tunnel plays start to finish inside `game/` from the debug panel, emits
`finished(result)`, `tools/run_tests.ps1` says 0 failed, and `tunnel/` no longer exists.

## 1. Design (settled unless marked open)

**Layout.** Tunnel keeps its own internal folders, because it has 30 scripts:
`game/minigames/tunnel/{scripts,scenes,art}/` and `player.tscn`.

| from `tunnel/` | to |
|---|---|
| `scripts/`, `scenes/`, `player.tscn` | `game/minigames/tunnel/` (same names) |
| `art/` files a scene or script references (`sprites`, `sfx`, `music`, `cg`, light textures, parts of `player`, `enemies`) | `game/minigames/tunnel/art/` |
| `art/` files nothing references, `concepts/`, `art/reference`, `art/layout concepts`, the loose concept PNGs, `cover.png` | `source_art/tunnel/` |
| `tests/test_*.{gd,tscn}` | moved to `game/tests/tunnel_*.{gd,tscn}` and ported in step 6 (done) |
| `tests/profile_*`, `tests/compare_*`, `tools/` | `tools/tunnel/` |
| `design.md`, `README.md`, `docs/` | `docs/tunnel/` |
| `build/` (1.9 GB, git-ignored, holds stale script copies), `.godot/`, `export_presets.cfg`, `icon.svg`, `project.godot` | not ported; gone when `tunnel/` is deleted |

**Segment root.** `tunnel_segment.tscn` / `tunnel_segment.gd`, same contract as the runner:
`begin(args)`, `finished(result)`, never changes scene. It owns:

- a `SubViewport` with a 1280×720 canvas (`size_2d_override`, stretch on), sized to the window's
  real pixels, so the tunnel keeps its layout and stays sharp inside the 960×540 game;
- a chamber slot inside that viewport, holding one chamber (or the intro) at a time;
- the three former autoloads as child nodes.

**Autoloads become nodes.** The game allows one autoload (`GameState`).

- `game_manager.gd` becomes `class_name TunnelManager` with `static var i: TunnelManager`, set in
  `_enter_tree()` and cleared in `_exit_tree()`. Every `GameManager.x` (about 110 references)
  becomes `TunnelManager.i.x`: a mechanical replace with no behaviour change.
- `music_manager.gd` and `pause_menu.gd` have no outside callers; they only move under the root.

**Scene changes become chamber swaps.** `go_to_chamber(path)` frees the slot's child and
instantiates `path`; `respawn_player()` re-instantiates the same path instead of
`reload_current_scene()`. `TunnelManager.i.chamber` replaces `get_tree().current_scene` (5 places:
`game_manager.gd`, `music_manager.gd`, `catwalk_guard.gd`, `spotlight_sweep.gd`).

**Ending.** `ending_sequence.gd` stops restarting to the intro and asks the manager to finish;
the root emits `finished({"outcome": "escaped", "deaths": n})`.

**Input.** The root adds tunnel's actions (`interact`, `sprint`, `action_torch`, `action_hide`,
`restart`) in `_init()`, as `runner_segment.gd` does, so `project.godot` is untouched. Tunnel also
adds keys to `ui_left` / `ui_right`; those are added on enter and removed on exit so the VN's menus
are unaffected.

**Project settings.** Copy tunnel's four 2D physics layer names into `game/project.godot`. Nothing
else carries over. Renderer goes from Compatibility to Forward Plus (checked in step 8).

**Global names.** No `class_name` collides with the game's today. `Player` is generic but free;
leave it.

**Chambers.** The `chamber_N.tscn` files were generated and never hand-edited. From now on the
`.tscn` files are the source. The generators in `tools/tunnel/` stay archived and are not repointed
(step 3 edited paths inside the scenes, so regenerating would undo that).

**Pause.** Main owns the Esc key and pausing the tree. A segment may supply its own pause menu;
tunnel keeps its `pause_menu.gd` menu (volume, invincibility assist, restart chamber, controls), and
that is what shows while the tunnel segment runs. Main's `game/ui/pause.gd` stays the default for
segments that supply none. Main's pause menu is not designed yet.

**Start and ending.** Both are arguments:
`begin({"start": "intro" | "chamber_0", "ending": "sequence" | "none"})`. In the game the defaults
are `chamber_0` and `none` (a VN scene leads in and handles the ending; `finished` is emitted either
way). The demo passes `intro` and `sequence`. The story may still change which is used.

## 2. Procedure

| # | step | who | done when |
|---|---|---|---|
| 0 | Commit tunnel's pending work (done 2026-11-16, `cbe5a99` in tunnel's own repo, not pushed); the three open points are answered (see section 1); close Godot. Before step 9: the nested repo is pushed and tagged `jam-build` (see "Two repos"), and Wesley gives a keep-list for the git-ignored files in `tunnel/` (`mainguy.glb`, `mainguy_diffuse.png`, `mainguy_MR.png`, `_tools/`, `build/`) | you | `git status` clean |
| 1 | **Inventory.** Classify every tracked file in `tunnel/` (shipped / source art / tool / doc / test / drop) by checking what scenes and scripts reference. Append the table to this file | Sonnet | every file has a row; unreferenced art listed for your OK |
| 2 | **Move.** `git mv` per the layout table, each shipped file with its `.import` and `.uid` so UIDs survive; source art drops its `.import`; tools archived as they are. Godot stays closed and is not run until step 3 | Sonnet | `tunnel/` holds only what is not ported; commit |
| 3 | **Repoint paths.** Replace `res://scripts/`, `res://scenes/`, `res://art/`, `res://player.tscn`, `res://tests/` in `.gd` / `.tscn` / `.tres`; run `godot --headless --path game --import` | Sonnet | import reports no missing dependencies; commit |
| 4 | **Segment root and managers.** Write `tunnel_segment.*`; convert the three autoloads; chamber slot; viewport; input; ending → `finished`. **Done 2026-11-16** (`1b4f8a3`): checked headless by script (0 → 1, respawn, Esc, both endings); not yet played in a window | Opus | chamber 0 → 1 → respawn works in a window |
| 5 | **Reference sweep.** `GameManager.` → `TunnelManager.i.`; the 5 `current_scene` uses; the intro, exit, ending and pause callers. **Done 2026-11-16** (`c371b6c`, with step 4) | Sonnet | no `GameManager`, `change_scene_to_file`, `reload_current_scene` or `current_scene` left under `game/minigames/tunnel/` |
| 6a | **Test pattern.** Port `test_chamber1` (the largest) to run through the segment root under `run_tests.ps1`. **Done 2026-11-16**: `game/tests/tunnel_chamber1.*` on the shared base `game/tests/tunnel_test.gd`, whose header is the how-to; `run_tests.ps1` runs `tunnel_*` with `--fixed-fps 60` | Opus | that one test passes |
| 6b | **Remaining tests.** Port the other eleven `test_*` the same way, following the header of `game/tests/tunnel_test.gd` (`test_timed_door` had no `.tscn`; it was a `SceneTree` script, now a `Node` test with a new `.tscn`). **Done 2026-11-17**: all eleven ported to `game/tests/tunnel_*`, the parked `tests/` folder is gone; `run_tests.ps1`: 0 failed (17 tests). Changes beyond renames: chamber 5's "play again" check became "continue" (the ending now calls `finish()`) plus a check that Enter ends the segment; the main-scene check in `tunnel_intro` is kept as a `# NOT PORTED` comment; chamber 4's worm-kill check sets one heart (hearts postdate that test); `load_chamber` now waits out a respawn in progress, and `wait_dead()` was added to the base | Sonnet | `run_tests.ps1`: 0 failed |
| 7 | **Hook up.** Debug-panel entry that launches the segment; update `CLAUDE.md` (table row, In progress) | Sonnet | launches from F3; returns to the hub on finish |
| 7b | **Tunnel demo.** Build it by `docs/demo_spec.md` and compare against the live itch.io page | Opus | demo matches the live page |
| 8 | **Play check.** All five chambers in a window under Forward Plus; compare lighting against the old build; fix what differs | you, then Opus | you sign off on the look |
| 9 | **Retire.** Delete `tunnel/` (its `build/` included) and this plan's inventory table | Sonnet, on your yes | folder gone; tests still 0 failed |

**Two repos.** `tunnel/` is tracked twice: as plain files in this repo (where the port happens,
with `git mv`), and by its own nested repo `tunnel/.git` (GitHub `Wasumyon/Tunnel`, branch `main`).
Step 9 deletes the nested repo with the folder, so before step 9 push it and tag the last jam
commit (`git -C tunnel tag jam-build cbe5a99`, then push `main` and `jam-build`).

Steps 4 and 6a are the only ones that need judgment; everything else follows a table or a pattern.
Steps 4 and 5 can run in one chat if the Opus session has room, since 5 needs 4's names.

**Not part of the port:** where the tunnel sits in the calendar (a story decision). The itch.io
browser builds are specified in `docs/demo_spec.md`.

## 3. Inventory (step 1)

Generated 2026-11-16 from `git ls-files tunnel` (384 files) by a reachability script (roots: `scenes/**`, `scripts/**`, `player.tscn`; `res://` paths and `uid://` followed through `.tscn`/`.tres`/`.gd`; runtime-built paths resolved to their literal names, see 3.4). `.import` and `.uid` files count with their owner.

### 3.1 Summary

| category | files | size |
|---|---|---|
| shipped | 175 | 13.8 MB |
| source art | 141 | 86.0 MB |
| test | 35 | 63.9 KB |
| tool | 23 | 77.3 KB |
| doc | 4 | 33.4 KB |
| drop | 6 | 7.3 KB |
| **total** | **384** | **100.0 MB** |

### 3.2 Per directory

One row per directory and category. Counts include `.import`/`.uid` companions. "tool-needed" = source art a `tools/` script cannot run without.

| path | category | destination | files |
|---|---|---|---|
| `tunnel (top level files)` | doc | `docs/tunnel/` | 2 |
| `tunnel (top level files)` | drop | `not ported` | 6 |
| `tunnel (top level files)` | shipped | `game/minigames/tunnel/player.tscn` | 1 |
| `tunnel/art` | shipped | `game/minigames/tunnel/art` | 3 |
| `tunnel/art` | source art | `source_art/tunnel/art` | 8 |
| `tunnel/art/cg` | shipped | `game/minigames/tunnel/art/cg` | 2 |
| `tunnel/art/cg/fall_bg` | shipped | `game/minigames/tunnel/art/cg/fall_bg` | 2 |
| `tunnel/art/cg/fall_bg` | source art | `source_art/tunnel/art/cg/fall_bg` | 16 |
| `tunnel/art/enemies` | source art | `source_art/tunnel/art/enemies` | 17 |
| `tunnel/art/enemies/Model` | source art (10 tool-needed) | `source_art/tunnel/art/enemies/Model` | 10 |
| `tunnel/art/layout concepts` | source art | `source_art/tunnel/art/layout concepts` | 4 |
| `tunnel/art/music` | shipped | `game/minigames/tunnel/art/music` | 4 |
| `tunnel/art/player` | source art | `source_art/tunnel/art/player` | 8 |
| `tunnel/art/player/Model` | source art (10 tool-needed) | `source_art/tunnel/art/player/Model` | 10 |
| `tunnel/art/reference` | source art | `source_art/tunnel/art/reference` | 2 |
| `tunnel/art/sfx` | shipped | `game/minigames/tunnel/art/sfx` | 54 |
| `tunnel/art/sprites/chip` | shipped | `game/minigames/tunnel/art/sprites/chip` | 16 |
| `tunnel/art/sprites/chip` | source art | `source_art/tunnel/art/sprites/chip` | 12 |
| `tunnel/art/sprites/chip/raw` | source art | `source_art/tunnel/art/sprites/chip/raw` | 5 |
| `tunnel/art/sprites/chip/raw/new` | source art | `source_art/tunnel/art/sprites/chip/raw/new` | 13 |
| `tunnel/art/sprites/guard` | shipped | `game/minigames/tunnel/art/sprites/guard` | 2 |
| `tunnel/art/sprites/guard` | source art | `source_art/tunnel/art/sprites/guard` | 10 |
| `tunnel/art/sprites/mc` | shipped | `game/minigames/tunnel/art/sprites/mc` | 2 |
| `tunnel/art/sprites/mc` | source art (2 tool-needed) | `source_art/tunnel/art/sprites/mc` | 6 |
| `tunnel/art/sprites/mc/model` | shipped | `game/minigames/tunnel/art/sprites/mc/model` | 21 |
| `tunnel/art/sprites/mc/model` | source art (1 tool-needed) | `source_art/tunnel/art/sprites/mc/model` | 13 |
| `tunnel/concepts/scifi-pass` | source art | `source_art/tunnel/concepts/scifi-pass` | 7 |
| `tunnel/docs` | doc | `docs/tunnel/` | 2 |
| `tunnel/scenes` | shipped | `game/minigames/tunnel/scenes` | 2 |
| `tunnel/scenes/chambers` | shipped | `game/minigames/tunnel/scenes/chambers` | 6 |
| `tunnel/scripts` | shipped | `game/minigames/tunnel/scripts` | 60 |
| `tunnel/tests` | test | `game/tests/tunnel_*` | 35 |
| `tunnel/tests` | tool | `tools/tunnel/` | 6 |
| `tunnel/tools` | tool | `tools/tunnel/` | 17 |

Notes: `tests/` tool rows are `profile_*` and `compare_*` (6 files); test rows are the 12 `test_*` tests. Top-level doc rows are `design.md` and `README.md`; `docs/` holds `visual-pass.md` and `visual-pass.patch`. Top-level shipped is `player.tscn`; drops are `project.godot`, `icon.svg`(+`.import`), `.gitignore`, `.gitattributes`, `.editorconfig` (`export_presets.cfg` is not tracked).

### 3.3 Unreferenced art, needs the owner's OK

Source-art files sitting in a directory that also holds shipped files (each has a `.import` companion unless noted; it moves with it). The plan already expects the `art/` root ones (concepts, cover).

| path | size | note |
|---|---|---|
| `art/Underground Cavern Encounter.png` | 1.5 MB | expected by plan (concept/cover) |
| `art/War Idol Escape_ Flooded Industrial Cavern3.png` | 1.6 MB | expected by plan (concept/cover) |
| `art/War Idol_ Escape Underground2.png` | 1.6 MB | expected by plan (concept/cover) |
| `art/cg/fall_bg/2026-10-28_080156_vertical-2-3-portrait-background-illustration_1.png` | 2.3 MB |  |
| `art/cg/fall_bg/2026-10-28_080156_vertical-2-3-portrait-background-illustration_2.png` | 2.2 MB |  |
| `art/cg/fall_bg/2026-10-28_080156_vertical-2-3-portrait-background-illustration_3.png` | 2.3 MB |  |
| `art/cg/fall_bg/Chip fall-no bg.png` | 140.3 KB |  |
| `art/cg/fall_bg/chip fall.png` | 2.6 MB |  |
| `art/cg/fall_bg/chip_fall_red_1.png` | 2.0 MB |  |
| `art/cg/fall_bg/chip_fall_red_2.png` | 2.2 MB |  |
| `art/cg/fall_bg/chip_fall_yellow_red_2.png` | 2.1 MB |  |
| `art/cover.png` | 1.7 MB | expected by plan (concept/cover) |
| `art/sprites/chip/chip_fall_1.png` | 26.8 KB |  |
| `art/sprites/chip/chip_fall_2.png` | 27.1 KB |  |
| `art/sprites/chip/chip_kneel_1.png` | 24.0 KB |  |
| `art/sprites/chip/chip_kneel_2.png` | 22.4 KB |  |
| `art/sprites/chip/chip_landed_a.png` | 18.3 KB |  |
| `art/sprites/chip/chip_landed_b.png` | 17.2 KB |  |
| `art/sprites/guard/guard_animations.png` | 1.7 MB |  |
| `art/sprites/guard/guard_cutout_full.png` | 404.1 KB |  |
| `art/sprites/guard/guard_idle.png` | 43.0 KB |  |
| `art/sprites/guard/guard_walk_gen_1.png` | 1.1 MB |  |
| `art/sprites/guard/guard_walk_gen_2.png` | 1.3 MB |  |
| `art/sprites/mc/lantern.png` | 1019.4 KB | tool-needed |
| `art/sprites/mc/mc_cutout_full.png` | 379.1 KB |  |
| `art/sprites/mc/mc_idle.png` | 30.1 KB |  |
| `art/sprites/mc/model/mc_crouch_n.png` | 499.0 KB |  |
| `art/sprites/mc/model/mc_fall_n.png` | 274.9 KB |  |
| `art/sprites/mc/model/mc_limp_back_n.png` | 605.3 KB |  |
| `art/sprites/mc/model/mc_limp_n.png` | 272.0 KB |  |
| `art/sprites/mc/model/mc_sprint_n.png` | 254.0 KB |  |
| `art/sprites/mc/model/mc_walk_n.png` | 456.5 KB |  |
| `art/sprites/mc/model/torch_hands.json` | 6.5 KB | tool-needed (input of `tools/build_torch_frames.py`), no `.import` |
| **33 files** | **30.7 MB** | |

Directories that are entirely unreferenced (no shipped sibling): `art/enemies` (27 files, `Model/` tool-needed), `art/player` (18, `Model/` tool-needed), `art/sprites/chip/raw` (18), `art/layout concepts`, `art/reference`, `concepts/scifi-pass`. The plan expected parts of `art/player` and `art/enemies` to ship; nothing in them is referenced.

### 3.4 Dynamic references

| where | pattern | pulls in |
|---|---|---|
| `scripts/acid_pool.gd:113` | `"res://art/sfx/%s.wav" % s`, s in acid_squelch, acid_bubbles, acid_burst, worm_strike | 4 wav |
| `scripts/room0_fall.gd:67` | `"res://art/sfx/%s.wav" % s`, s in vent_knock, worm_strike, worm_lunge, land_thud, lamp_click | 5 wav (overlap with acid_pool/passage_vent) |
| `scripts/footsteps.gd:26` | `"res://art/sfx/step_%s_%s_%d.wav"`, (guard, player) x (concrete, metal) x 0..2 | 12 wav |
| `scripts/game_manager.gd:32` | `"res://scenes/chambers/chamber_%d.tscn"` | chamber_0..5 (all in `scenes/`, roots anyway) |
| `scripts/music_manager.gd:38,50` | `begins_with("res://scenes/chambers/chamber_")`, `load(path)` where path is the APEX/LEAP const | the 2 ogg (also literal consts) |
| `scripts/game_manager.gd:115` | `ResourceLoader.exists(path)` on a chamber path | nothing new |

Each list is a literal array in the same function, so they resolve to exact names. No `DirAccess`, `get_files` or `list_dir` in `scripts/` or `scenes/`.

### 3.5 Oddities

- No runtime file (`scenes/`, `scripts/`, `player.tscn`) references `res://tests/`, `res://tools/` or `res://build/`; 0 unresolved `res://` or `uid://` references.
- `art/sprites/mc/model/torch_hand_positions.gd` is a script inside `art/`, preloaded by `player.gd:108`; it moves with its `.uid` to `game/minigames/tunnel/art/...`.
- `art/sprites/mc/model/mc_*_n.png` (6 sheets: walk, sprint, crouch, fall, limp, limp_back) are unreferenced; `mc_frames.tres` uses `mc_<clip>.png` and `mc_torch_*.png`.
- Tools write into and read `res://art/...` paths (`render_torch_sprites.gd`, `render_guard_sprites.gd`, `prepare_lantern.gd`, `build_torch_frames.py`), including `art/player/Model/*`, `art/enemies/Model/*`, `sprites/mc/lantern.png`, `torch_hands.json` (source art after the move). They will not run unchanged from `tools/tunnel/`; archive, do not repoint.
- `tools/gen_chamber_*.py` and `tools/apply_visual_pass.py` target the chamber scenes (settled: the `.tscn` files are the source; generators stay archived).
- Filenames with spaces (10 files, plus `.import`): `art/Underground Cavern Encounter.png`, `art/War Idol Escape_ Flooded Industrial Cavern3.png`, `art/War Idol_ Escape Underground2.png`, `art/cg/chip saved reveal.png` (shipped, preloaded at `ending_sequence.gd:15`), `art/cg/fall_bg/Chip fall-no bg.png`, `art/cg/fall_bg/chip fall.png`, `art/enemies/miner monster concepts.png`, `art/enemies/miner monster turn around.png`, 2 files in `art/layout concepts/`.
- `art/reference/.gdignore` hides that folder from Godot; it is source art and moves with `chip.png` (neither has an `.import`).
- No duplicate `class_name` among tracked `.gd`; no absolute paths (`C:\`, `/Users/`) in tracked scripts, scenes, tools or tests.
- `project.godot` autoloads GameManager, MusicManager, PauseMenu (main scene `res://scenes/intro.tscn`, Compatibility renderer); all dropped except as handled in step 4.
- Source-art files include `.import` sidecars; they can move with the art or be dropped once outside a Godot project (not decided).
