# Restructure plan (decided 2026-11-16)

Rename and regroup so the names say what things are. **Sonnet** does the mechanical steps below;
have Opus review the diff of steps 4-7. One step = one commit. Godot closed for every step.
After each step: `powershell -File tools/run_tests.ps1` (must say 0 failed), then
`godot --headless --path <project> --import` (no missing-resource or script errors), then grep the
whole repo (not `_archive/`, not `.claude/worktrees/`) for the old name or path: nothing may remain.

## Decided names
| now | becomes |
|---|---|
| `car/` | `sandbox/` (**done**) |
| `vn/` (the project folder) | `game/` |
| `vn/scenes/`, plus `opener/`, `first_shot/` and the VN player (`vn.gd`, `vn.tscn`, `inline_marks.gd`, `script_effect.gd`) | `story/` |
| `vn/runner/`, `vn/stealth/`, later `tunnel/` | `game/minigames/runner/`, `.../stealth/`, `.../tunnel/` |
| `vn/img/`, `vn/sfx/` (shared) | `game/assets/img/`, `game/assets/sfx/` |
| `vn/phone/`, pause and debug layers | `game/ui/` |
| `MainGame` (`main_game.gd/.tscn`) | `Main` (`main.gd/.tscn`) |
| `Game` autoload | `GameState` |
| `campaign_phone.gd` | `phone.gd` |
| `vn_game_design.md` | `game_design.md` (**done**) |
| root docs | `docs/`; unshipped art -> `source_art/` (snake_case); `.ps1` at root -> `tools/` (**done**) |

Kept: `hub/`, `dossier/`, `calendar/`, `autoload/`, "segment", "calendar".
Done (2026-11-16): inside the runner, `slice.*` -> `run.*` and `runner.gd` (the player vehicle) -> a clearer
name (`player_craft.gd`); the group "runner" became "player". `runner_placeholder.*` deleted.

## Steps
1. **Done:** `car/` -> `sandbox/`, references updated. `tools/run_tests.ps1` added.
2. **Done:** repo root cleanup. Docs in `docs/` (+ `docs/stories/`, `docs/boundarypush/`), art in
   `source_art/` (incl. `prompts/`, `music/`, `raw/`, `review_thumbs/`), scripts in `tools/`.
   `vn_game_design.md` became `docs/game_design.md`. Dossier `source:` lines, code comments, scene
   comments and the `.ps1` paths were rewritten; the scripts now point at the live `vn/` folders,
   not `sandbox/vn/`. Left for the user to decide: `docs/opencode.md` (empty) and
   `docs/io_vanguard_story_bible.md` (an older near-duplicate of the bible).
3. **Wait:** stealth playtest finished and committed. Then tell Fable the new names.
3. **Done:** stealth work was committed first (Fable has the new names).
4. **Done:** `vn/` -> `game/`.
5. **Done**, one commit each: `scenes/`, `opener/`, `first_shot/` and the VN player -> `game/story/`
   (the written text stays in `story/scenes/`: "scene" is the writers' word for it); `runner/`,
   `stealth/` -> `minigames/`; `img/`, `sfx/` -> `assets/`; `phone`, `pause`, `debug` -> `ui/`
   (`campaign_phone.gd` -> `phone.gd`).
6. **Done:** `MainGame` -> `Main` (`main.gd/.tscn`, node, `main_scene`, tests, docs;
   `maingame_spec.md` -> `main_spec.md`).
7. **Done:** `Game` -> `GameState` (`autoload/game_state.gd`).
8. **Done:** CLAUDE.md rewritten for the new layout, old names retired in a line there.
9. Later: tunnel ported into `game/minigames/tunnel/` as a real segment (copy, repoint paths,
   wrapper, re-theme), after the jam build is settled. Runner internals: done (see above).

Note: right after a batch of moves the first headless `--import` can print a transient
"can't load autoload / f.is_null()" error from the old `.godot/` cache; a second import is clean.
