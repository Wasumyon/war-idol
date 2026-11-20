# Runner routes — spec

**Written by:** Claude, 2026-11-19   **Status:** proposed (Wesley to confirm §2)
**Code:** `game/minigames/runner/`   **Design:** `docs/game_design.md`, "Routes and lanes", "Difficulty"

How the runner is split into maps ("routes") that differ in enemies, background, pacing and
the shape of the road, and how each is tested. Built in four tickets (§8). Nothing here makes a
calendar day, a route's place in the story or a payout final: those stay provisional (CLAUDE.md).

## 1. Today
- The calendar passes `{route, zone}` to `runner_segment.gd` (`calendar_data.gd`: easy/supply_road,
  medium/perimeter, hard/sulfur_pits). The segment stores it and ignores it.
- All tuning is `@export` values on `lane_spawner.gd` and constants in `run.gd`.
- One backdrop (`art/backdrop/`, wired in `run.tscn`), one ground palette (`ground.gdshader`).
- Randomness is the global `randf()`/`randi()` in the spawner and in `battle_pocket.gd`,
  `drone.gd`, `fighter.gd`, `hazard_emitter.gd` and `run.gd` (donations). Runs cannot be replayed.
- The road is flat and straight.

## 2. Zone and route (proposed)
- **`zone` is the map**: look, enemy roster, pacing, road shape, run length. One data file per zone.
- **`route` is the difficulty** (`easy`, `medium`, `hard`, later `premium`): a small table of
  multipliers on top of the zone. One zone can then be offered at several difficulties.
- An unknown zone falls back to `supply_road` with a warning; an unknown route to `medium`.

The design doc says "routes are maps"; this reading keeps both fields the calendar already has.
**[OPEN] Wesley confirms**, or says zone and route are one thing (then the difficulty table folds
into the zone file).

## 3. `RouteDef` — one resource per zone
`game/minigames/runner/route_def.gd` (`class_name RouteDef extends Resource`), one `.tres` per
zone in `game/minigames/runner/routes/<zone>.tres`. Fields, grouped:

| group | fields |
|---|---|
| id | `zone_id`, `display_name` |
| run | `duration`, `start_shields`, `follow_per_sec`, `donation_rate` |
| look | `sky_texture`, `far_texture`, ground `flat_dark`, `flat_light`, `track_color` |
| ground layer | `spawn_ahead`, `row_spacing`, `spawn_chance`, `emitter_chance`, `emitter_min_gap`, `flat_chance` |
| air layer | `air_interval`, `air_spawn_ahead`, `hover_chance`, `max_hover`, `drone_shots` (the shot types this zone uses, with weights) |
| battles | `battle_interval`, `cluster_min`, `cluster_max`, `pocket_x`, `cluster_x_spread`, `cluster_z_spread`, `cluster_z_min`, `cluster_z_max` |
| lasers | `laser_interval` (0 = none) |
| pacing (ticket 004) | `intensity: Curve` over run time 0..1, multiplying every spawn rate |
| road shape (ticket 005) | `bend_x: Curve`, `bend_y: Curve` over distance, `bend_scale` |
| timeline (later) | `timeline: Array[Dictionary]` of `{t, kind, params}`, the Chaac run format (`docs/chaac_run_spec.md` §7) |

New enemy kinds join a roster field; the spawner does not grow a branch per zone.

## 4. Difficulty table (ticket 004)
`ROUTES` in `route_def.gd`: per route, `spawn_rate`, `intensity_max`, `follower_mult`, `money_mult`.
Starting values (tune in playtests): easy 0.75 / 0.7 / 1.0 / 1.0; medium 1.0 / 0.85 / 1.25 / 1.25;
hard 1.3 / 1.0 / 1.6 / 1.6. Danger is still sold by presentation, not failure rate
(`game_design.md`, "Difficulty: tuned for feeling").

## 5. Seeded randomness
`run.gd` owns one `RandomNumberGenerator`. `begin()` may pass `seed` (an int); without it the run
randomizes. The spawner and everything it spawns draw from that generator (handed over before
`add_child`); no runner script calls the global `randf`/`randi`. Same seed + fixed frame rate =
the same run, which is what makes the tests in §7 possible.

## 6. The undulating road (ticket 005)
**Bend the picture, not the road.** Gameplay keeps straight lanes in straight coordinates. A
vertex function displaces what is drawn by its distance `d` ahead of the camera:
`offset.x = curve_x * d²`, `offset.y = curve_y * d²`, where `curve_x/curve_y` are the zone's
bend curves sampled at the distance travelled, pushed each frame as global shader uniforms.
- Collisions, dodging and spawning do not change. Near the player `d` is small, so the drawn
  position matches the collision position.
- Every runner material gets the bend: the ground shader, and the code-built materials of the
  enemies, which move to one shared `ShaderMaterial` / shader include.
- **Filming must use the bent position.** `_film_target()` unprojects targets; with the bend on,
  a far target is drawn elsewhere. A `RunnerBend.visual(pos)` helper in GDScript, the same formula
  as the shader, is used wherever the code unprojects a world position.
- The backdrop rig shifts in X (and Y) with the current curvature so the horizon swings with turns.
- `bend_scale = 0` turns it off (and is the default until a zone sets it).

## 7. Tests
All headless, in `game/tests/`, run by `tools/run_tests.ps1`. Runner tests run at `--fixed-fps 60`
like the tunnel tests.
1. **Data** (`runner_routes`): every `zone` named in `calendar_data.gd` has a `.tres`; each loads,
   its textures exist, weights are positive, counts are in order (`cluster_min <= cluster_max`).
2. **Wiring**: `begin({zone, route})` puts that def on the run; an unknown zone falls back with a
   warning; the current smoke test still passes.
3. **Replay**: two runs with the same seed log the same spawns (kind, lane, time) over 10 s;
   different seeds differ.
4. **Spawn simulation** (ticket 003): the spawner alone, against a fake player at constant speed,
   90 s of game time per zone and route. Checks: hard > medium > easy in hazards per minute;
   spawn density follows the intensity curve; no row blocks all 5 lanes; a laser never lands
   within one row of a ground hazard in every lane; at most one battle cluster at a time.
5. **Bend** (ticket 005): offset is 0 at the camera; `RunnerBend.visual` matches the shader
   formula; a target far ahead on a bent stretch can still be filmed.
6. **By eye**: F3 panel entry (F7 is free) to start a run with a chosen zone, route and seed,
   jump to time t, toggle the bend, show the current intensity. Wesley checks the bend in a window.
7. **Later, optional**: a bot that dodges naively, 20 seeds per route at high `time_scale`, logs
   survival time and followers: a balance canary, not pass/fail. A per-run log to `user://`
   (hits, grazes, followers over time) for jam playtests.

## 8. Build order (one ticket each, each reviewed before the next)
| ticket | what | play changes? |
|---|---|---|
| 002 | `RouteDef` + three zone files holding today's values; segment loads by zone; seeded RNG; tests 1–3 | none |
| 003 | spawn simulation test (test 4, without the intensity and difficulty checks) | none |
| 004 | difficulty table + intensity curve; test 4 in full; F3 entry | yes |
| 005 | the bend (§6), test 5 | yes, Wesley checks in a window |

After 005: give each zone its own look and roster (art and tuning, with Wesley), then the
timeline format for hand-made routes.
