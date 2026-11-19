# War Idol — status

Updated at the end of every session (see `AGENTS.md`, Hand-off). Last update: 2026-11-19.

## Focus
- **The runner and the stealth minigame.** Both will be playtested through upcoming game jams.
- Story is written as it comes; ideas that turn up mid-build go to `docs/story_inbox.md`.

## Next
- Runner: playtest it in a window inside `game/`, then hook followers and money into the payouts.
- Stealth: next build step in `docs/stealth_spec.md` (steps 1–3 are in).
- Tunnel port: step 8 next (Wesley's play check in a window), per `docs/tunnel_port_plan.md`. Step 7 done: F3 panel / F6 launches the tunnel from the hub (`debug_tunnel` on Main); not in the calendar; `tunnel_from_main` test covers the round trip.
- Demo builds: the shell (`game/demo/`) and the tunnel web demo are built (2026-11-17); `tools/export_demo.ps1 tunnel` makes the zip. Next: Wesley tries it in a browser (below), then the runner demo, then stealth (`docs/demo_spec.md`, build order).
- Ticket 001 (open): the default player name in code becomes Phoroneus.
- Day 1 opening run: build order in `docs/chaac_run_spec.md` §10.

## Waiting on Wesley
- Review the porcelain prop finish and two alternate colors in source_art/porcelain-prop-study.svg.
- Review the cel-shaded parade costume turnaround for Aysel in `source_art/aysel-parade-model-sheet.png`.
- Try the tunnel demo in a browser and compare it with the live itch.io page: run `powershell -File tools/export_demo.ps1 tunnel`, then `python -m http.server 8000 --directory build/demo/tunnel/web` (a web build will not run by double-clicking `index.html`), open http://localhost:8000, play to the end. Upload it yourself when happy (steps in the session report; itch.io: new page, HTML5, upload the zip from `build/demo/tunnel/`).
- The feedback link for the demos' result screen: put the URL in `FEEDBACK_URL` in `game/demo/demo_shell.gd` (or give it to Claude).
- Play the tunnel from F3 (or F6) in a window and sign off on the look (tunnel port step 8).
- A yes or no on the outline's proposed beats and punchlist B10–B14.
- Dossier spec §9 story points; stealth spec §10 points.
- The open story items in the decisions log ("Still open").

## Threads
- **Main design review (2026-11-18).** Wesley's direction on pacing and interviews is in `docs/game_design.md`. Revisit whether Albrecht's interview is optional or fixed once his early appearance is written. Try the two-slot rhythm in playtests before considering a third.
- **Restructure** (done 2026-11-16; the plan is archived). **Old names are retired**: `car/`, `vn/` as the project folder, `MainGame`, the `Game.` autoload, `maingame_spec.md`, `vn_game_design.md`, `campaign_phone.gd`, `HANDOVER.md`, and in the runner `slice.*`, `runner.gd`, `runner_placeholder.*`. `tools/stale_names.ps1` (run by the tests) fails if one comes back in `game/` or the live docs.
- **itch.io demos** of tunnel, runner and stealth, exported from `game/`: `docs/demo_spec.md` (approved 2026-11-17). Shell + tunnel demo built and checked in a browser up to chamber 0; nothing uploaded. Runner and stealth demos: one entry in `game/demo/demo_entries.gd` and one preset each.
- **Tunnel Escape:** finished as a jam piece. Being ported into `game/minigames/tunnel/` by `docs/tunnel_port_plan.md` (steps 1–6 committed 2026-11-16/17: it runs as a segment, `tunnel_segment.tscn`, and all twelve tunnel tests run through it; step 7 added a debug-panel launch; not yet played in a window). The three open points are answered and settled in the plan.
- `docs/outline.md` is in the bible's three acts (2026-11-15). Its *proposed* beats and punchlist
  B10–B14 wait on a yes before scenes are written against them.
- Fill the calendar: days 2–40 are placeholders, placed by `docs/main_spec.md` §2.
- Runner: ported into `game/minigames/runner/` behind the segment contract (2026-11-16), a straight copy, not playtested in a window. Next: playtest, then hook its followers/money into the outcome payouts (the calendar currently pays fixed per-outcome amounts).
- The hub's real room (3D bunker, characters possibly 2D); News/Stats is a stub.
- Dossiers: built from `docs/dossier_spec.md` (merged 2026-11-16), four placeholder entries, no
  `@ file` in any scene yet. Next: settle its §9 story points, then write entries and file them in scenes.
- Stealth minigame: specced in `docs/stealth_spec.md` (2026-11-15); build steps 1–3 are in (map, guards and detection, noise and concealment); its §10 points are open.
- Update `GameState` stats to match `docs/game_design.md` (the dials), and move `lane_x()` out of it.
