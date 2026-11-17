extends Node
## Shared base for the tunnel tests. Not a test itself (no .tscn), so run_tests.ps1 skips it.
##
## HOW TO PORT A TUNNEL TEST (from game/minigames/tunnel/tests/test_X.gd)
##  1. `git mv` test_X.gd and test_X.tscn to game/tests/tunnel_X.gd / .tscn (keep the .uid with
##     the .gd); in the .tscn point the script at res://tests/tunnel_X.gd. The parked folder's
##     tests/ has the old .tscn root names; keep them.
##  2. First line: `extends "res://tests/tunnel_test.gd"`. Delete the test's own copies of
##     ok(), shot(), wait(), release(), and its fails/checks/shots vars: they are here.
##  3. In _ready(), call `run()` as before. At the top of run(), `await start_segment()`
##     (begin args optional, e.g. {"ending": "sequence"} for chamber 5's ending).
##  4. Where the old test did `sc = load(CHAMBER).instantiate(); add_child(sc)`, write
##     `await load_chamber(CHAMBER)`. That fills `sc` (the chamber) and `p` (its Player),
##     resets checkpoint/lives/busy, and swaps the chamber in at once with no fade.
##     A chamber added as the test's own child is no longer under the manager: never do that.
##  5. `GameManager.` -> `m.` (the TunnelManager; constants as TunnelManager.X).
##     `get_tree().current_scene` -> `m.chamber`. `change_scene_to_file(path)` /
##     `reload_current_scene()` -> `await load_chamber(path)` or `m.respawn_player()`.
##  6. End with `finish()` instead of printing RESULT and quitting yourself.
##     The jam tests set `GameManager._busy = true` so a death would not reload the chamber.
##     That still works (`m._busy = true` after load_chamber, `m._busy = false` before the next
##     one: load_chamber waits out a busy manager), but while it is set worm hits do nothing
##     and the player's input and the first-sight line are off. Where a test needs those, let
##     the respawn run and read deaths with `await wait_dead(sec)` instead of `await wait(sec)`
##     then `p.is_dead`: a death frees the player ~1.5 s later.
##     Hearts: with more than one, a worm hit costs a heart and throws the player clear;
##     on the last heart it kills. A check that wants a worm death sets `m._set_lives(1)`.
##     Long tests: start_segment({}, 600.0) lifts the 110 s game-time limit (it runs fast).
##  7. Keep every check. One that no longer makes sense behind the segment root stays as a
##     commented line with the reason (`# NOT PORTED: ...`).
##  8. Run `powershell -File tools/run_tests.ps1`; it must say 0 failed. It runs every
##     tunnel_*.tscn with --fixed-fps 60, as the jam project did: tunnel's tweens run on frame
##     time and its player on physics ticks, so timing checks are only steady at a fixed rate.
##     The name must start with tunnel_ for that. To run one by hand:
##     godot --headless --fixed-fps 60 --path game res://tests/tunnel_X.tscn
##
## Screenshots: set SHOTS=<dir> and run without --headless; shot() saves the tunnel's own
## 1280x720 viewport, not the game window.

const SEGMENT := preload("res://minigames/tunnel/tunnel_segment.tscn")

var fails := 0
var checks := 0
var shots := OS.get_environment("SHOTS")
var seg: Node        ## the TunnelSegment root
var m: TunnelManager ## TunnelManager.i
var sc: Node         ## the chamber in the slot
var p: Player        ## that chamber's player
var results: Array[Dictionary] = []  ## every finished(result) the segment emitted


func ok(c: bool, name: String) -> void:
	checks += 1
	if not c:
		fails += 1
	print(("PASS " if c else "FAIL ") + name)


## Start the segment (default start chamber_0, ending none) and wait for it to settle.
## A test that hangs on a script error quits with code 2 after `timeout_sec`.
func start_segment(args: Dictionary = {}, timeout_sec: float = 110.0) -> void:
	get_tree().create_timer(timeout_sec, true, false, true).timeout.connect(func() -> void:
		print("FAIL timed out after %d s" % int(timeout_sec))
		get_tree().quit(2))
	seg = SEGMENT.instantiate()
	seg.begin(args)
	seg.finished.connect(func(r: Dictionary) -> void: results.append(r))
	add_child(seg)
	await get_tree().process_frame
	m = TunnelManager.i
	# Skip the opening fade-in so screenshots and light checks see the room.
	m._fade_rect.modulate.a = 0.0
	sc = m.chamber
	p = _player()


## Replace the slot's chamber with a fresh `path` at once (no fade), clearing the
## checkpoint and restoring lives. Waits out any respawn in progress. Fills `sc` and `p`.
func load_chamber(path: String) -> void:
	release()
	# A death in the last scenario leaves a respawn running; let it finish, or it would
	# swap the new chamber out from under the test.
	while m.is_transitioning():
		await get_tree().process_frame
	m.clear_checkpoint()
	m._busy = false
	m._set_lives(TunnelManager.MAX_LIVES)
	m._swap(path)
	await get_tree().process_frame
	sc = m.chamber
	p = _player()


## Wait for a respawn or chamber change the manager is doing, then refresh `sc` and `p`.
func settle() -> void:
	while m.is_transitioning():
		await get_tree().process_frame
	sc = m.chamber
	p = _player()


func wait(sec: float) -> void:
	for i in int(sec * 60.0):
		await get_tree().physics_frame


## Wait up to `sec`; true as soon as the player is dead. With the manager live, a death
## starts a respawn that frees this player ~1.5 s later, so a check "he is dead after
## the wait" must catch the death while it lasts (a freed player counts as dead).
func wait_dead(sec: float) -> bool:
	for i in int(sec * 60.0):
		if not is_instance_valid(p) or p.is_dead:
			return true
		await get_tree().physics_frame
	return not is_instance_valid(p) or p.is_dead


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func release() -> void:
	for action: StringName in [&"ui_right", &"ui_left", &"sprint", &"action_hide"]:
		Input.action_release(action)


func shot(name: String) -> void:
	if shots == "" or seg == null:
		return
	await RenderingServer.frame_post_draw
	var vp: SubViewport = seg.get_node("Screen/Viewport")
	vp.get_texture().get_image().save_png(shots.path_join(name + ".png"))


## Print the summary run_tests.ps1 reads and quit (1 if any check failed).
func finish() -> void:
	release()
	print("RESULT %d/%d" % [checks - fails, checks])
	print("%d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


func _player() -> Player:
	if sc == null:
		return null
	return sc.find_child("Player", true, false) as Player
