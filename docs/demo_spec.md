# Demo builds — spec

Status: draft, not approved; mechanisms marked unverified must be checked in Godot 4.7 on the first build.

## Purpose
Browser builds of tunnel, runner and stealth for playtesting, exported from `game/` so playtesters run
the same code the game ships. One itch.io page per minigame; runner and stealth can stay unlisted.
The live tunnel page (the jam build) stays untouched until its demo from `game/` matches it.

## Demo shell
One shared scene in `game/demo/`: title screen, controls screen, the segment, then a result screen
with restart and a feedback link. It calls the segment's `begin(args)` and listens for
`finished(result)` exactly as Main does (segment contract: `docs/main_spec.md` §5). Per-minigame data
(title, controls text, segment scene path, begin args) sits in one small table or resource. Tunnel's
args: `{"start": "intro", "ending": "sequence"}` (`docs/tunnel_port_plan.md`, section 1).

## Export presets
One web preset per minigame: `demo_tunnel`, `demo_runner`, `demo_stealth`. Each exports only the
selected scenes and their dependencies, so no story text (`game/story/scenes/`) or dossier entries
are in the download.

## Unverified, settle on the first build
- How a preset starts on the shell instead of Main. Candidates: a custom feature tag per preset with
  a feature-tagged `application/run/main_scene` override, or Main checking `OS.has_feature` at start.
- Web exports use the Compatibility renderer; the game is Forward Plus. Check each demo's look in a
  browser. Tunnel was authored in Compatibility; the runner is the one at risk.

## Rules
- The shell never writes `user://campaign.save`.
- No debug panel and no F-keys (the visor reveal must not leak the twist).
- A build stamp (date and short commit) shows on the title screen.

## Tooling
- `tools/export_demo.ps1 <name>` builds the web zip into a git-ignored folder.
- The root `.gitignore` ignores `export_presets.cfg`; it must be tracked for `game/`.
- Uploading to itch.io is done by Wesley, or by an agent only when he says so for that upload.

## Feedback
Playtest feedback goes to `docs/punchlist.md` with the build stamp, as `AGENTS.md` says.

## Build order
1. Shell + tunnel demo (compare against the live page). 2. Runner. 3. Stealth.
