# Visual decluttering pass — October 30, 2026

Implemented against the existing working files, preserving their earlier uncommitted edits. No gameplay scripts for guards, vents, searchlight, acid, switches, movement or hiding were changed.

## Exact changes

- `scenes/chambers/chamber_0.tscn`: ten uniform side-wall worm clusters (100 stalks) become six clusters (33 stalks), in this order:

  | World Y | Stalks |
  | --- | --- |
  | -3000 | 3 |
  | -2300 | 4 |
  | -1800 | 5 |
  | -1400 | 6 |
  | -1050 | 7 |
  | -720 | 8 |

  Spawn remains Y=-4050. With the existing 520px knock lead, the first reveal begins after 530px of clear descent. Cluster spacing narrows toward the bottom. All four back-wall lungers remain; the first two move from -3050/-2230 to -2600/-2050 so they join later. Last two remain at -1400/-820. Disable ShaftSpill1 and ShaftSpill3, keeping the hole, alternating spill lights, exit and player presence glow.
- `scripts/room0_fall.gd`: hide entire side-wall clusters at startup, including rubble, and reveal each only when its knock begins. Growth already started at zero. Dust per knock/strike/landing drops from 10/18/30 to 5/9/16. Falling speed, safe strike timing, landing, controls and audio are unchanged.
- `scenes/chambers/chamber_1.tscn`: each of the three wall rows uses 14 stalks instead of 22 (42 total versus 66). Widths, height, solidity, light reach, row timing and acid hazard remain unchanged. Disable the broad WarmHaze light, retain strip lights and acid glow.
- `scenes/chambers/chamber_2.tscn`: decorative CeilingWorms uses 4 stalks instead of 8. Disable WarmHaze. Keep both gameplay worm gates, guard, vents, switches and lamps.
- `scenes/chambers/chamber_3.tscn`: disable ChasmGlow and alternating Fill1/Fill3/Fill5. Keep Fill0/Fill2/Fill4 and ExitLight, plus every searchlight/guard light. No guard or vent was removed or retuned. The existing first sweep starts at X=650, first pillar at X=800, first guard patrol begins at X=950, first vent at X=1550: the searchlight establishes the entrance threat before the layered section.
- `scenes/chambers/chamber_4.tscn`: disable Haze; retain bed glows, exit light, both catwalk guards and every deadly worm cluster.
- `scripts/tubeworm_cluster.gd`: visual redraw at up to 30Hz, skip redraw submissions off screen using a generously padded notifier that follows cluster rotation. All light overlap, growth, blocking and kill checks continue every physics tick. Curves use 8 segments instead of 10 and crowns use 7 feathers instead of 9. Exposed settings allow restoration: redraw_fps=0, cull_offscreen_drawing=false, curve_segments=10, plume_feathers=9.

Nine decorative lights are disabled, retained as editable nodes. Scene-authored enabled PointLight2D counts for Rooms 0–4: 6→4, 6→5, 6→5, 8→4, 5→4. These counts exclude lights created dynamically by scripts.

Room 3 source contains only BridgeGuard and BridgeGuard2. The user clarified that the reported third guard may have come from earlier discussion about introducing catwalk guards. This pass preserves the guards actually present; it does not invent a new patrol.

## Global effects and performance

No ambient fog shader or persistent ambient particle emitter exists in this checkout. The haze nodes above are large decorative lights. The global HUD vignette is a static gradient texture. The lantern shader samples its own sprite texture, not the whole screen. Autoloads provide transitions, music and pause UI; no global fog effect was found. The shared procedural worm renderer was the clearest recurring visual cost even in Room 1.

Native OpenGL Compatibility comparison at 1280×720 on an RX 6800 XT, near Room 1's worm wall: approximately 1,760 draw calls before, 968 after (45% fewer). Room 3 entrance remained about 45 draw calls; lights do not map directly to this counter. Room 4's dynamic patrol/light/growth states differed during sampling, so its counts are not a controlled comparison. Frame timings varied strongly and were sometimes worse after changes: no FPS or frame-time improvement is established. This is not a Web/browser benchmark. Browser profiling remains needed before claiming a Web speedup.

`tests/compare_visual_pass.tscn` reproduces the native sampling using local before snapshots, with original worm visual settings on its baseline branch. It writes screenshots and prints mean/p95 process time and draw calls. The runs are sequential, with active hazards; use the limitations above when interpreting them. Screenshots in `build/visual-room{1,3,4}-{before,after}.png` were visually inspected for readable silhouettes and hazard lighting.

## Verification

Godot 4.7.2:

- New `tests/test_visual_pass.tscn`: all 24 checks pass (empty opening, increasing density, reveal depth, safe landing, later strikes, preserved guards and searchlight-first entrance).
- Room 1: 20/20, including wall blocking, sequential lamp retraction, regrowth and the complete acid crossing.
- Room 3: 22/22 both before and after, including searchlight kills, pillar safety, distraction and exit patrol behavior.
- Room 4: 26/26, including full scripted crossing, deadly worms, safe fringe, core shooting, hiding and both guards.
- Passage vents: all 8 checks pass, including warning, strike, light retraction and guard response.
- Guard 2: 28/30 both before and after. Existing failures: lamp beyond the open exit door does not trigger pursuit; guard does not reach that player. Baseline uses the pre-pass Room 2 scene. Unrelated pursuit behavior was left unchanged.
- Editor import found no script parse errors. Environment reports root-certificate/cache/editor-settings access errors; existing suites also report shutdown resource leaks. These are not clean-log runs.
- `git diff --check` and reverse-patch applicability check pass.

Headless suites can run with `--headless --fixed-fps 60 --path . res://tests/<test>.tscn`; fixed FPS advances deterministic test time quickly.

## Reapply and rollback

`python tools/apply_visual_pass.py` reapplies the scene changes after running a chamber generator. It is idempotent. The existing generators are otherwise unchanged; regenerating scenes without this follow-up will overwrite scene tuning.

`docs/visual-pass.patch` contains only this pass's changes to the seven existing runtime files (two scripts, five scenes), measured against the saved working files rather than Git HEAD. To review or restore, first run `git apply --reverse --check docs/visual-pass.patch`, then `git apply --reverse docs/visual-pass.patch`. The applicability check succeeded at completion. Later edits may require resolving overlap; avoid restoring from Git HEAD, which would lose earlier user work. New test/helper/report files can remain without affecting gameplay.

Exact local before copies are also retained under ignored `build/visual-pass-before/`. No changes were committed or published.

## Room 3 follow-up — pillar safety and approaching opening sweep

The searchlight drew pillar shadow cutouts but its player detection checked only pool distance and the Hide state. Fixed `scripts/spotlight_sweep.gd` so detection also respects `_in_shadow(player_x)`, using the exact same spans as the drawn pool. Standing in any pillar shadow is now safe from this searchlight without pressing Hide. Guard and vent detection remain independent.

Changed `Searchlight.start_x` from 650 to 1700 in both `scenes/chambers/chamber_3.tscn` and `tools/gen_chamber_3.py`. The pool and glow start beyond the initial camera's right edge and sweep left toward the entrance at the existing 240px/s. This supersedes the earlier X=650 opening described above; sweep speed, bounds, catch time and shot timing remain unchanged.

Expanded `tests/test_chamber3.gd` to check the offscreen pool/glow against the actual camera bounds, standing safety at the left/centre/right of all five shadows, exposure immediately outside their edges, and an entire sweep past the first pillar without Hide. Reproduced 18 failures before the fix (31/49 passed); all 49 checks pass after the fix, including existing open-deck kills, hiding and guard-distraction behavior. Godot still reports the previously noted environment/shutdown warnings.

The earlier `visual-pass.patch` restores only the initial decluttering pass; it does not contain this follow-up change.
