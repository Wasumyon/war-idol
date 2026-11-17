# War Idol — status

Updated at the end of every session (see `AGENTS.md`, Hand-off). Last update: 2026-11-16.

## Focus
- **The runner and the stealth minigame.** Both will be playtested through upcoming game jams.
- Story is written as it comes; ideas that turn up mid-build go to `docs/story_inbox.md`.

## Next
- Runner: playtest it in a window inside `game/`, then hook followers and money into the payouts.
- Stealth: next build step in `docs/stealth_spec.md` (steps 1–3 are in).
- Tunnel port: next step in `docs/tunnel_port_plan.md`.
- Day 1 opening run: build order in `docs/chaac_run_spec.md` §10.

## Waiting on Wesley
- A yes or no on the outline's proposed beats and punchlist B10–B14.
- Dossier spec §9 story points; stealth spec §10 points.
- The open story items in the decisions log ("Still open").

## Threads
- **Restructure** (done 2026-11-16, `docs/restructure_plan.md`): `car/` → `sandbox/`, `vn/` → `game/`, `MainGame` → `Main`, autoload `Game` → `GameState`, `scenes/` etc. regrouped under `story/`, `minigames/`, `assets/`, `ui/`; docs in `docs/`, art in `source_art/`. **Old names are retired** (`car/`, `vn/` as the project folder, `MainGame`, `Game.`, `maingame_spec.md`, `vn_game_design.md`); if you see them, they are stale. Runner internals renamed too: `slice.*` → `run.*`, `runner.gd` → `player_craft.gd`, node/group `Runner`/`runner` → `Player`/`player`, `runner_placeholder.*` deleted.
- **Tunnel Escape:** finished as a jam piece. Being ported into `game/minigames/tunnel/` by `docs/tunnel_port_plan.md` (steps 1–3 committed).
- `docs/outline.md` is in the bible's three acts (2026-11-15). Its *proposed* beats and punchlist
  B10–B14 wait on a yes before scenes are written against them.
- Fill the calendar: days 2–40 are placeholders, placed by `docs/main_spec.md` §2.
- Runner: ported into `game/minigames/runner/` behind the segment contract (2026-11-16), a straight copy, not playtested in a window. Next: playtest, then hook its followers/money into the outcome payouts (the calendar currently pays fixed per-outcome amounts).
- The hub's real room (3D bunker, characters possibly 2D); News/Stats is a stub.
- Dossiers: built from `docs/dossier_spec.md` (merged 2026-11-16), four placeholder entries, no
  `@ file` in any scene yet. Next: settle its §9 story points, then write entries and file them in scenes.
- Stealth minigame: specced in `docs/stealth_spec.md` (2026-11-15); build steps 1–3 are in (map, guards and detection, noise and concealment); its §10 points are open.
- Update `GameState` stats to match `docs/game_design.md` (the dials), and move `lane_x()` out of it.
