# War Idol

Design and prototype repository. A war-journalism story set on Io, and a
2.5D vehicle "filming runner" prototype built in Godot.

## Layout

| Folder / file | Contents |
|---|---|
| `game/` | **The game**: the Godot 4.7 project (Main, calendar, story, hub, runner, stealth, tunnel, dossier). |
| `sandbox/` | Old Godot sandbox project: the runner prototype (`slice/`), car-physics tests. Frozen. |
| `tunnel/` | Leftovers of the Tunnel Escape jam project. Its files now live in `game/minigames/tunnel/`, `docs/tunnel/`, `tools/tunnel/` and `source_art/tunnel/`; the port is in progress (`docs/tunnel_port_plan.md`) and this folder is deleted at its last step. It no longer runs on its own. |
| `docs/` | Design docs: story bible, canon, outline, specs, punchlists, the design-doc `.docx`, prose in `stories/`. |
| `source_art/` | Unshipped art: `characters/`, `backgrounds/`, `enemy_models/`, `environment_concept_art/`, `ui_base/`, `raw/` (`.clip`, source images), prompts. |
| `tools/` | Scripts (`run_tests.ps1`, asset and reading-copy generators). |
| `_archive/` | Superseded docs. |

## Running the game

Import `game/project.godot` in Godot 4.7.x and press **F5** (it opens Main). Tests: `powershell -File tools/run_tests.ps1`.

## Running the runner prototype (old sandbox)

1. Install **Godot 4.7.x** (standard build, no .NET needed).
2. Import `sandbox/project.godot` (or run the same runner in the game, `game/minigames/runner/`).
3. Open `sandbox/slice/slice.tscn` and press **F6** (run current scene).

**Controls**

| Input | Action |
|---|---|
| A / D (or arrows) | Strafe a lane |
| W | Boost |
| S | Duck / take cover |
| Ctrl | Slow |
| Space | Jump |
| Shift | Dash (super armour; smashes obstacles) |
| Mouse | Aim the viewfinder |
| Right mouse | Zoom (slower, tighter) |
| Left mouse | Camera snap (good-snap toast) |
| Side mouse buttons | Duck (alt) |
| R | Restart |

**Notes**
- `.godot/` is git-ignored; Godot regenerates it the first time you open the project.
- The prototype is a **grey-box test build** — some art is still placeholder.
- The **visual novel** player is `game/story/vn.tscn`. Scenes are plain text in `game/story/scenes/`. (`sandbox/vn/` is an older copy.)
- `sandbox/test.tscn` is a driving sandbox and `sandbox/test_static.tscn` is an asset-viewer rig; neither is the game.

## Git

- Repo: private, `Wasumyon/war-idols`.
- `.docx` and images are binary: commit before destructive edits; history is the only recovery.
