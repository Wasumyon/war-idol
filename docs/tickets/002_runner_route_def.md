# Ticket 002 — runner zone files and seeded randomness

**For:** GPT (Sol)   **Written by:** Claude, 2026-11-19   **Status:** built; 20 tests, 0 failed; awaiting Claude review and Wesley playtest

## Goal
The runner reads its tuning and backdrop from one data file per zone, chosen by the calendar's
`zone` arg, and all its randomness comes from one seeded generator. **The game plays exactly as
it does today**: the three zone files hold today's values. This is a refactor plus tests.

## Read first
- `AGENTS.md`, `CLAUDE.md`
- `docs/runner_routes_spec.md` §1, §3, §5, §7 (tests 1–3). Only those sections are in this ticket.
- `game/minigames/runner/`: `runner_segment.gd`, `run.gd`, `run.tscn`, `lane_spawner.gd`,
  `battle_pocket.gd`, `drone.gd`, `fighter.gd`, `hazard_emitter.gd`, `backdrop.gd`
- `game/tests/runner_smoke.gd`, `tools/run_tests.ps1`
- `game/calendar/calendar_data.gd` (the runner entries' `args`)

## You may change
- `game/minigames/runner/*.gd` (the scripts listed above), and `run.tscn` only if a node path or
  export has to change
- new: `game/minigames/runner/route_def.gd`, `game/minigames/runner/routes/supply_road.tres`,
  `perimeter.tres`, `sulfur_pits.tres`
- new: `game/tests/runner_routes.gd` + `runner_routes.tscn`
- `game/tests/runner_smoke.gd` only if it must follow a rename
- `tools/run_tests.ps1`: only the line that adds `--fixed-fps 60`, so it also applies to `runner_*`
- `docs/tickets/002_runner_route_def.md`: the Status line

## Do not touch
- Story docs, canon, scene text, `calendar_data.gd`, `GameState`, `sandbox/`, art files,
  and anything not listed above.
- Do not build the difficulty table, the intensity curve, the bend or the timeline (later tickets).
  Do not add fields for them to `RouteDef` yet.

## Decisions you need
- `zone` picks the map file; `route` (easy/medium/hard) is difficulty and is **ignored in this
  ticket** apart from being stored. Proposed in the spec, not yet confirmed by Wesley, which is
  why nothing may depend on it yet.
- Unknown or missing zone → load `supply_road` and `push_warning` once.
- The segment contract does not change: `begin(args)` before entering the tree,
  `finished({outcome, followers, money})`, never changes scene. `R` restart and `Enter` continue
  work as now.

## Steps
1. Commit the current state if anything is uncommitted that you touch (nothing should be).
2. `route_def.gd`: `class_name RouteDef extends Resource` with `@export` fields for the spec §3
   groups **id, run, look, ground layer, air layer, battles, lasers**. Every default equals
   today's value (from `run.gd` constants and `lane_spawner.gd` exports; ground colours from
   `ground.gdshader`'s uniform defaults). `drone_shots`: the four shot types with equal weight,
   which reproduces today's `randi() % 4` pick. Add `static func load_zone(zone: String) -> RouteDef`
   that loads `res://minigames/runner/routes/<zone>.tres` with the fallback above.
3. Three `.tres` files: `zone_id`, `display_name`, and the textures from `run.tscn`
   (`io_sky.webp` sky, `io_terrain.png` far). Everything else stays at the default. They are
   identical in play for now; that is intended.
4. `run.gd`: add `var route_def: RouteDef` and `var rng: RandomNumberGenerator`, both set by the
   segment before `add_child`. If either is null at `_ready` (the scene run on its own), load
   `supply_road` / make a randomized generator. Replace `DURATION`, `START_SHIELDS`,
   `FOLLOW_PER_SEC`, `DONATION_RATE` with the def's values. Apply `sky_texture`, `far_texture`
   and the ground colours to the Backdrop Sky/Far materials and the Ground shader parameters
   (duplicate the material first so the `.tscn` resource is not changed at runtime).
   The donation `randf_range` uses `rng`.
5. `runner_segment.gd`: in `_start_run`, load the def from `_args.zone`, make the generator
   (`seed = _args.seed` if given, otherwise randomize), set both on the run, then `add_child`.
   `R` restart: same seed if one was given, a new random one otherwise.
6. `lane_spawner.gd`: remove the `@export` tuning; read every value from the run's `route_def`
   (the spawner is a child of the run root; get it in `_ready`). Every `randf`/`randi`/
   `randf_range`/`randi_range` uses the run's `rng`. Pass `rng` to each `BattlePocket`, `Drone`,
   `HazardEmitter` before `add_child`; `BattlePocket` passes it to its `Fighter`s. In those
   scripts use `rng` when it is set, the global functions when it is null.
   Add `var spawn_log: Array[Dictionary]`: every spawn appends `{kind, lane, z}` (`kind` one of
   `target`, `emitter`, `drone_hover`, `drone_cross`, `laser`, `battle`; `lane` -1 when it has
   none; `z` rounded to an int).
7. `tools/run_tests.ps1`: apply `--fixed-fps 60` to `runner_*` tests as well as `tunnel_*`.
8. `game/tests/runner_routes.gd/.tscn`, printing `ok`/`FAIL` lines and quitting non-zero on
   failure, in the style of `runner_smoke.gd`:
   - every `zone` in `calendar_data.gd`'s `SEGMENTS` args has a `.tres` that loads as `RouteDef`,
     with both textures non-null, positive intervals, `cluster_min <= cluster_max`;
   - `begin({"zone": "sulfur_pits"})` → the run's `route_def.zone_id == "sulfur_pits"`;
     an unknown zone → `supply_road`;
   - the def's values reach the run: a run from a def with `duration = 5` has a 5 s timer;
   - replay: two segments with `seed = 1234` each run 600 frames; their `spawn_log`s are equal
     and non-empty. A run with `seed = 99` gives a different log.
9. Run `powershell -File tools/run_tests.ps1`. Then commit (one commit for the ticket is fine).

## Done when
- [ ] The runner plays as before (same feel, same backdrop); the calendar's runner offers still start it
- [ ] No runner script calls the global `randf`/`randi`/`randf_range`/`randi_range` except as
      the null fallback in step 6
- [ ] `powershell -File tools/run_tests.ps1` says 0 failed
- [ ] committed (do not commit unrelated files already modified in the tree, e.g. `AGENTS.md`)

## Report back
What changed, in plain words. How to check it. The test output summary. Any question you stopped
on, at the top. Anything in today's code that did not fit the def (say so; do not invent fields).
