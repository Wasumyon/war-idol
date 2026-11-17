extends Node
## Headless checks for the shallow pool, worm wall, and deep crossing.
## Set SHOTS=<dir> for screenshots.
var fails := 0
var checks := 0
var shots := OS.get_environment("SHOTS")
var sc: Node
var p: Player
var wall
var pool

const WALL_X := 1300.0      # middle of three clusters, 210 apart
const WALL_FIRST := 1090.0
const WALL_LAST := 1510.0
const SHALLOW_STALK_X := 589.0
const POOL_X := 2260.0
const DANGER_X := 2230.0    # worm bed starts here
const POOL_LEFT := 1889.0
const ENTRY_STALK_X := 2032.0
const CHECKPOINT_X := 1800.0
const CHAMBER := "res://minigames/tunnel/scenes/chambers/chamber_1.tscn"

func ok(c: bool, name: String) -> void:
	checks += 1
	if not c: fails += 1
	print(("PASS " if c else "FAIL ") + name)

func shot(name: String) -> void:
	if shots == "": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))

func wait(sec: float) -> void:
	for i in int(sec * 60.0):
		await get_tree().physics_frame

func release() -> void:
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	Input.action_release("sprint")

func setup(x: float) -> void:
	release()
	if sc:
		sc.queue_free()
		await get_tree().process_frame
	GameManager.clear_checkpoint()
	GameManager._busy = false
	GameManager._set_lives(GameManager.MAX_LIVES)
	sc = load(CHAMBER).instantiate()
	add_child(sc)
	await get_tree().process_frame
	p = sc.find_child("Player", true, false)
	wall = [sc.find_child("TubewormWall", true, false), sc.find_child("TubewormWall2", true, false), sc.find_child("TubewormWall3", true, false)]
	pool = sc.find_child("AcidPool", true, false)
	p.global_position = Vector2(x, 0)
	var cam = sc.find_child("MainCamera", true, false)
	cam.global_position = p.global_position + Vector2(0, -130)
	cam.reset_smoothing()
	await wait(0.4)

func _ready() -> void:
	run()

func run() -> void:
	await get_tree().process_frame
	GameManager._fade_rect.modulate.a = 0.0

	await setup(300.0)
	var shallow: AcidPool = sc.find_child("ShallowAcidPool", true, false)
	Input.action_press("ui_right")
	await wait(1.65)
	release()
	ok(p.global_position.x > 665.0 and not p.is_dead and shallow.state == AcidPool.State.IDLE,
			"walking straight through the shallow pool in darkness is safe")
	ok(p.acid_pool == null, "the dry bank restores full traction")

	await setup(SHALLOW_STALK_X)
	shallow = sc.find_child("ShallowAcidPool", true, false)
	p.set_torch(true)
	await wait(1.05)
	ok(shallow.state == AcidPool.State.WARN and shallow._warning_mark.visible and not shallow._in_danger,
			"the isolated pair warns with the lamp lit")
	ok(p.acid_pool == shallow and shallow.glow != pool.glow, "the shallow pool applies its own traction and glow")
	await shot("ch1_shallow_warning")
	Input.action_press("ui_right")
	await wait(0.65)
	release()
	ok(p.global_position.x > 665.0 and not p.is_dead and shallow.state == AcidPool.State.IDLE,
			"moving up the far bank escapes the shallow warning")

	# 1 the worm wall blocks in the dark
	await setup(700)
	Input.action_press("ui_right")
	await wait(3.0)
	ok(p.global_position.x < WALL_FIRST - 60 and not p.is_dead, "dark: the worm wall stops him (x %d)" % int(p.global_position.x))
	await shot("ch1_1_wall_dark")
	# 2 lamp parts it
	p.set_torch(true)
	await wait(0.8)
	await shot("ch1_2_wall_lit")
	var t := 0.0
	ok(wall[0].growth < 0.3 and wall[1].growth > 0.9 and wall[2].growth > 0.9, "lamp: only the front row parts at first")
	var shot_mid := false
	var one_at_a_time := true
	var closed_behind := false
	var stops := 0
	var was_stopped := false
	while t < 12.0 and p.global_position.x < WALL_LAST + 250:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var x := p.global_position.x
		# the row two ahead of the one he's in is still up
		if x < WALL_FIRST + 60 and wall[2].growth < 0.9: one_at_a_time = false
		if x > WALL_LAST and wall[0].growth > 0.5: closed_behind = true
		var stopped: bool = absf(p.velocity.x) < 30.0
		if stopped and not was_stopped and t > 0.3: stops += 1
		was_stopped = stopped
		if not shot_mid and x > WALL_X - 40:
			shot_mid = true
			await shot("ch1_2b_wall_inside")
	ok(p.global_position.x >= WALL_LAST + 250, "lamp: pushes through all three rows (%.1f s)" % t)
	ok(one_at_a_time, "rows part one at a time, not all at once")
	ok(stops >= 2, "he has to pause at the rows (%d pauses)" % stops)
	ok(closed_behind, "rows close again behind him")
	release()

	# 3 dark closes on him, but floor worms never attack
	await setup(WALL_X)
	p.set_torch(true)
	await wait(1.0)
	p.set_torch(false)
	await wait(3.5)
	ok(wall[1].growth > 0.9 and wall[0].growth > 0.9 and not p.is_dead, "dark closes the wall around him; floor worms never attack")

	# 4 checkpoint right before the pool
	await setup(POOL_X - 520)
	Input.action_press("ui_right")
	await wait(0.6)
	release()
	ok(GameManager.has_checkpoint and absf(GameManager.checkpoint.x - CHECKPOINT_X) < 2.0, "checkpoint right before the pool (%d)" % int(GameManager.checkpoint.x))
	var hint: Label = sc.get_node("HUD/HUD/HintLabel")
	ok(not hint.visible, "pool checkpoint does not reveal the crossing solution")
	await shot("ch1_3_pool_idle")

	# 5 dark wading: slow, warning, then the worms
	await setup(POOL_LEFT - 60)
	var warned := [-1.0]
	var struck := [-1.0]
	var clock := [0.0]
	var wf := [0]
	var sf := [0]
	pool.warning_started.connect(func(): warned[0] = clock[0]; wf[0] = Engine.get_physics_frames())
	pool.struck.connect(func(): struck[0] = clock[0]; sf[0] = Engine.get_physics_frames())
	Input.action_press("ui_right")
	var entry_walk_speed := 0.0
	var shot_warn := false
	var shot_strike := false
	var warned_in_safe := false
	var shot_safe := false
	while clock[0] < 8.0 and GameManager.lives == 3:
		await get_tree().physics_frame
		clock[0] += 1.0 / 60.0
		if pool.state == pool.State.WARN and p.global_position.x < DANGER_X: warned_in_safe = true
		if not shot_safe and pool._wading and p.global_position.x > POOL_X - 150:
			shot_safe = true
			await shot("ch1_3_pool_safe_half")
		if pool._wading and p.global_position.x > ENTRY_STALK_X and p.global_position.x < DANGER_X:
			entry_walk_speed = maxf(entry_walk_speed, absf(p.velocity.x))
		if warned[0] > 0 and not shot_warn and clock[0] - warned[0] > 0.35:
			shot_warn = true
			await shot("ch1_5_dark_warning")
		if struck[0] > 0 and not shot_strike and clock[0] - struck[0] > 0.2:
			shot_strike = true
			await shot("ch1_6_strike")
	release()
	ok(is_equal_approx(entry_walk_speed, p.max_speed), "forward speed stays unchanged in the shallows")
	ok(not warned_in_safe, "walking in darkness clears the entry stalk before it reacts")
	ok(warned[0] > 0 and struck[0] > 0, "dark, worm bed: bubbling warning, then they burst up")
	var warn_s: float = float(sf[0] - wf[0]) / Engine.physics_ticks_per_second
	ok(absf(warn_s - pool.warn_time) < 0.04, "deep warning lasts %.2f s" % warn_s)
	ok(not p.is_dead and GameManager.lives == 2 and p.global_position.x < POOL_LEFT,
			"dense worms cost a heart and throw the player back to the near bank")

	await setup(ENTRY_STALK_X)
	await wait(0.4)
	ok(pool.state == pool.State.WARN and pool._warning_mark.visible, "lingering at the first stalk shows the bubbling warning")
	await shot("ch1_entry_warning")
	Input.action_press("ui_left")
	await wait(0.65)
	release()
	ok(not p.is_dead and pool.state == pool.State.IDLE and not pool._warning_mark.visible, "walking back cancels the entry warning")

	await setup(ENTRY_STALK_X)
	await wait(1.8)
	ok(not p.is_dead and GameManager.lives == 2 and p.global_position.x < POOL_LEFT,
			"ignoring the entry warning lets the first stalk throw the player back")

	await setup(ENTRY_STALK_X)
	p.set_torch(true)
	await wait(0.45)
	ok(pool.state == pool.State.IDLE, "the lantern initially delays the entry warning")
	await wait(0.67)
	ok(pool.state == pool.State.WARN and pool._warning_mark.visible,
			"lingering with the lantern on eventually gives the same red warning")
	ok(pool.lit_time == 0.0, "the entry warning uses none of the dense-bed lamp time")
	Input.action_press("ui_left")
	await wait(0.45)
	release()
	ok(not p.is_dead and pool.state == pool.State.IDLE, "retreat cancels the entry warning with the lantern on")

	await setup(ENTRY_STALK_X + 50.0)
	Input.action_press("ui_right")
	await wait(0.2)
	release()
	Input.action_press("ui_left")
	await wait(0.12)
	ok(p.velocity.x > 0.0, "reversing in acid briefly carries momentum in the old direction")
	await wait(0.3)
	ok(p.velocity.x < 0.0, "the player regains traction and reverses")
	release()

	await setup(ENTRY_STALK_X + 50.0)
	Input.action_press("ui_right")
	await wait(0.2)
	release()
	await wait(0.14)
	ok(is_zero_approx(p.velocity.x), "releasing movement still stops promptly in acid")

	# 6 stepping back out during the warning: they sink back
	await setup(DANGER_X + 30)
	p.set_torch(true)
	pool.lit_time = 0.0
	await wait(0.3)
	p.set_torch(false)
	await wait(0.05)
	ok(pool.state == pool.State.WARN, "dark: the warning starts as soon as he's in")
	Input.action_press("ui_left")
	await wait(1.2)
	release()
	ok(not p.is_dead and pool.state == pool.State.IDLE, "back out of the acid during the warning: safe")

	# 7 lamp on during the dark warning pushes them back down
	await setup(DANGER_X - 60)
	Input.action_press("ui_right")
	while pool.state == pool.State.IDLE:
		await get_tree().physics_frame
	release()
	await wait(0.2)
	p.set_torch(true)
	await wait(0.5)
	ok(not p.is_dead and pool.state == pool.State.IDLE, "lamp on during the warning: they sink back")

	# 8 lamp on, walking: the light only buys time, he's caught partway
	await setup(DANGER_X - 60)
	p.set_torch(true)
	await wait(0.3)
	Input.action_press("ui_right")
	var shot_lit := false
	t = 0.0
	while t < 8.0 and not p.is_dead and p.global_position.x < POOL_X + 330:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if not shot_lit and pool.state == pool.State.WARN:
			shot_lit = true
			await shot("ch1_4_lit_wading")
	release()
	ok(GameManager.lives < 3, "lamp on but walking costs a heart near the far bank")

	# 9 lamp on, sprinting: makes it across
	await setup(POOL_LEFT - 60)
	p.set_torch(true)
	await wait(0.3)
	Input.action_press("ui_right")
	while p.global_position.x < DANGER_X - 50:
		await get_tree().physics_frame
	Input.action_press("sprint")
	var shot_run := false
	var max_lit := 0.0
	t = 0.0
	while t < 5.0 and not p.is_dead and p.global_position.x < POOL_X + 360:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		max_lit = maxf(max_lit, pool.lit_time)
		if not shot_run and pool._wading and pool.lit_time > 0.65:
			shot_run = true
			await shot("ch1_7_lit_sprint")
	release()
	ok(not p.is_dead and p.global_position.x >= POOL_X + 360,
			"lamp on, walk the near half, sprint the worm bed: across safely (lit %.2f s of %.2f)" % [max_lit, pool.light_hold_time])
	ok(p.acid_pool == null, "full traction again out of the acid")

	# Starting Shift after entering the dense bed still leaves time to get clear.
	await setup(DANGER_X - 60)
	p.set_torch(true)
	Input.action_press("ui_right")
	while p.global_position.x < DANGER_X + 40.0:
		await get_tree().physics_frame
	Input.action_press("sprint")
	await wait(1.6)
	release()
	ok(not p.is_dead and p.global_position.x > POOL_X + 307.0, "late sprint still clears the pool")

	# 10 full run: walk, lamp, wall, sprint the pool, reach the exit
	await setup(0)
	Input.action_press("ui_right")
	t = 0.0
	var reached := false
	while t < 30.0 and not p.is_dead:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var x := p.global_position.x
		if x > WALL_FIRST - 400 and not p.is_torch_on: p.set_torch(true)
		if x > DANGER_X - 50 and x < POOL_X + 330: Input.action_press("sprint")
		else: Input.action_release("sprint")
		if x > 2820: reached = true; break
	release()
	ok(reached and not p.is_dead, "full run reaches the exit (%.1f s)" % t)

	await check_respawn_hints()

	print("RESULT %d/%d" % [checks - fails, checks])
	get_tree().quit(1 if fails > 0 else 0)


func check_respawn_hints() -> void:
	sc.queue_free()
	await get_tree().process_frame
	GameManager.reset_death_hints()
	GameManager.set_checkpoint(Vector2(CHECKPOINT_X, 0.0))
	# Keep this runner alive while the real current scene reloads.
	get_tree().current_scene = null
	get_tree().change_scene_to_file(CHAMBER)
	await get_tree().scene_changed
	var hints: Array[String] = []
	GameManager.respawn_hint.connect(func(line: String) -> void:
		hints.append(line)
		ok(not GameManager.is_transitioning() and GameManager._fade_rect.modulate.a == 0.0,
				"hint is emitted after the respawn fade")
	)

	await GameManager.respawn_player()
	GameManager._set_lives(GameManager.MAX_LIVES)
	var player: Player = get_tree().current_scene.get_node("Player")
	player.global_position = Vector2(SHALLOW_STALK_X, 31.0)
	await wait(2.4)
	while GameManager.is_transitioning():
		await get_tree().process_frame
	ok(is_instance_valid(player) and GameManager.lives == 2 and hints.is_empty(),
			"a shallow-pool hit keeps the same player without advancing the deep-pool hint")
	player = get_tree().current_scene.get_node("Player")
	player.kill()
	while GameManager.is_transitioning():
		await get_tree().process_frame
	ok(hints.is_empty(), "manual restart and unrelated death show no pool hint")
	GameManager._set_lives(GameManager.MAX_LIVES)

	for attempt: int in 4:
		player = get_tree().current_scene.get_node("Player")
		# Walk through the checkpoint again if the previous death started a fresh set of lives.
		if not GameManager.has_checkpoint:
			player.global_position = Vector2(CHECKPOINT_X, 0.0)
			await wait(0.12)
		player.global_position = Vector2(ENTRY_STALK_X, 60.0)
		await wait(2.45)
		while GameManager.is_transitioning():
			await get_tree().process_frame
		ok(hints.size() == (0 if attempt < 2 else 1),
				"pool death %d gives the hint only on the third death" % (attempt + 1))
		if attempt == 2:
			ok(hints == [AcidPool.DEATH_HINT], "the checkpoint hint explains the deep crossing")
			var respawned: Player = get_tree().current_scene.get_node("Player")
			ok(absf(respawned.global_position.x) < 2.0 and GameManager.lives == 3,
					"the last heart restarts the chamber and restores all hearts")
			var bubble: PanelContainer = respawned.get_node_or_null("RespawnHint")
			ok(bubble != null and bubble.is_visible_in_tree(), "the respawned player displays the speech bubble")
			await shot("ch1_checkpoint_hint")
