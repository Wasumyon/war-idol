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
| `vn_game_design.md` | `game_design.md` |
| root docs | `docs/`; unshipped art -> `source_art/` (snake_case); `.ps1` at root -> `tools/` |

Kept: `hub/`, `dossier/`, `calendar/`, `autoload/`, "segment", "calendar".
Not now: inside the runner, `slice.*` -> `run.*` and `runner.gd` (the player vehicle) -> a clearer
name; the code uses group names such as "runner". Delete `runner_placeholder.*` then.

## Steps
1. **Done:** `car/` -> `sandbox/`, references updated. `tools/run_tests.ps1` added.
2. **Repo root cleanup** (no game files touched; safe any time): `docs/`, `source_art/`, `.ps1` into
   `tools/`. Update every path in CLAUDE.md, README, HANDOVER and the specs. Fix `commission.ps1` /
   `make_*.ps1` paths.
3. **Wait:** stealth playtest finished and committed. Then tell Fable the new names.
4. **`vn/` -> `game/`.** Folder only. Fix `.claude/launch.json`, the test runner, docs.
5. **Folder moves**, one commit each: `scenes/` -> `story/` (with the VN player, `opener/`,
   `first_shot/`); `runner/`, `stealth/` -> `minigames/`; `img/`, `sfx/` -> `assets/`; `phone/` and
   pause/debug -> `ui/`. Rewrite `res://` strings in `.gd`, `.tscn`, `.tres`, `project.godot`; the
   VN scene `.txt` files if they name image or sound paths; `calendar_data.gd` sources.
6. **`MainGame` -> `Main`.** Files, class_name, the `main_scene` setting, tests, docs.
7. **`Game` -> `GameState`.** Its own step: autoload entry in `project.godot`, every `Game.` use,
   tests, docs. Grep `\bGame\b` and read each hit; the word also appears in prose.
8. Rewrite CLAUDE.md's table and rules for the final layout; retire the old names in a line there.
9. Later: tunnel ported into `minigames/tunnel/` as a real segment (copy, repoint paths, wrapper,
   re-theme), after the jam build is settled.
