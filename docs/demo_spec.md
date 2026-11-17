# Demo builds — spec

Status: approved 2026-11-17. The two points the draft left unverified were settled on the first
build (shell + tunnel demo, 2026-11-17): see "How a demo starts" and "Renderer" below.

## Purpose
Browser builds of tunnel, runner and stealth for playtesting, exported from `game/` so playtesters run
the same code the game ships. One itch.io page per minigame; runner and stealth can stay unlisted.
The live tunnel page (the jam build) stays untouched until its demo from `game/` matches it.

## Demo shell
One shared scene in `game/demo/` (`demo_shell.tscn` / `demo_shell.gd`): title screen, controls screen,
the segment, then a result screen with "Play again", "Title screen" and a feedback link. It calls the
segment's `begin(args)` and listens for `finished(result)` exactly as Main does (segment contract:
`docs/main_spec.md` §5). Per-minigame data (title, blurb, controls, segment scene path, begin args,
result labels) sits in one table, `game/demo/demo_entries.gd`; only `tunnel` is filled in, and runner
and stealth are one entry each. The shell has no minigame-specific code. Tunnel's args:
`{"start": "intro", "ending": "sequence"}` (`docs/tunnel_port_plan.md`, section 1).

The feedback URL is the constant `FEEDBACK_URL` in `demo_shell.gd`, a marked placeholder until Wesley
supplies it; while empty the button shows "Feedback link coming soon", disabled.

## How a demo starts (settled)
Each preset sets two custom features: `demo` and `demo_<name>`. `game/project.godot` has one extra
line, `application/run/main_scene.demo="res://demo/demo_shell.tscn"`, a feature-tagged override of the
main scene. Main is untouched: in the editor and in a normal game export the `demo` feature is absent,
so the game still starts on `main/main.tscn`. The shell then plays the entry whose `demo_<name>`
feature is present.

Checked in Godot 4.7.2: an export writes the preset's custom features into `project.binary`
(`_custom_features`) and the override is resolved at start-up. Running the exported tunnel pack with
`--main-pack` started the shell, although Main's scene is not in the pack at all; the web build opened
on the shell's title screen in a browser.

## Renderer (settled for tunnel)
Web exports use the Compatibility renderer (WebGL 2); the game is Forward Plus. For tunnel this makes
no visible difference. Checked: the chamber-0 test's screenshots under Forward Plus and under
`--rendering-method gl_compatibility` (desktop, in a window) match by eye, lantern and darkness
included; the exported web build, played in a Chromium browser from the title through the intro (skipped with Enter) into chamber 0 with
the lantern on, looks the same and logs no errors. Headless runs use a dummy renderer, so they prove
only that the scripts run. Not yet compared: the whole run to the ending, Firefox/Safari, and the
live jam page side by side. The runner (3D) is the one still at risk; check it on its build.

## Export presets
One web preset per minigame in `game/export_presets.cfg` (tracked; the root `.gitignore` ignores
`export_presets.cfg` everywhere else): `demo_tunnel` now; `demo_runner`, `demo_stealth` later. Each
uses "export selected scenes": the shell, the segment's scenes, plus an include filter for its own
folder (`demo/*`, `minigames/tunnel/*`), because segments load chambers, sounds and sprites by path
strings, which the dependency scan cannot see. Threads off (`variant/thread_support=false`), so the
page needs no special server headers on itch.io.

What ships besides the minigame: `GameState` (every autoload is always exported; the shell never calls
it, and it only reads a save that does not exist in a browser) and `main/transition.gd` (the fade).
Confirmed by listing the pack: `tools/export_demo.ps1` exports the same preset a second time as a zip
pack, lists it into `build/demo/<name>/pack_contents.txt`, and fails if anything from `story/`,
`dossier/`, `ui/`, `hub/`, `calendar/`, `tests/` or `main/main.*` is in it. The first tunnel build
(238 files) had none; its project-wide caches (`uid_cache.bin`, class cache) name only tunnel, demo,
`transition.gd` and `game_state.gd`.

## Rules
- The shell never writes `user://campaign.save` (it never calls `GameState`; the test checks it).
- No debug panel and no F-keys (the visor reveal must not leak the twist): Main and `ui/` are not in
  the pack.
- A build stamp (date and short commit, `+changes` if `game/` had uncommitted edits) shows on the
  title and result screens. Outside an export it reads "dev build".

## Tooling
- `powershell -File tools/export_demo.ps1 <name>` builds `build/demo/<name>/web/` and
  `build/demo/<name>/war-idol-<name>-demo-<date>-<commit>.zip` (git-ignored). It writes the stamp to
  `game/demo/build_stamp.txt` for the export and removes it after. It needs Godot's web export
  templates for the installed version; if they are missing it says how to install them and stops.
- Trying a build locally needs a web server (browsers will not run it from `file://`):
  `python -m http.server 8000 --directory build/demo/<name>/web`, then open `http://localhost:8000`.
- `game/tests/demo_tunnel` runs the shell with the tunnel entry to the result screen and back,
  and checks no save is written.
- Uploading to itch.io is done by Wesley, or by an agent only when he says so for that upload.

## Feedback
Playtest feedback goes to `docs/punchlist.md` with the build stamp, as `AGENTS.md` says.

## Build order
1. Shell + tunnel demo (built 2026-11-17; compare against the live page). 2. Runner. 3. Stealth.
