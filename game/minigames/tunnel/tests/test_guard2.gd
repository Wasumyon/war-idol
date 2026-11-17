extends Node
var fails := 0
var checks := 0
var root_scene: Node
var g
var p
const CHAMBER := "res://minigames/tunnel/scenes/chambers/chamber_2.tscn"

func ok(c: bool, name: String) -> void:
	checks += 1
	if not c: fails += 1
	print(("PASS " if c else "FAIL ") + name)

func wait(sec: float) -> void:
	for i in int(sec * 60.0):
		await get_tree().physics_frame

func setup(guard_x: float, facing: int, player_x: float, torch := false) -> void:
	if root_scene: root_scene.queue_free(); await get_tree().process_frame
	root_scene = load(CHAMBER).instantiate()
	add_child(root_scene)
	await get_tree().process_frame
	g = root_scene.find_child("Guard", true, false)
	p = root_scene.find_child("Player", true, false)
	g.global_position.x = guard_x
	g.facing = -facing; g._set_facing(facing)
	g.state = EnemyGuard.State.WAIT; g._wait_timer = 99.0
	p.global_position = Vector2(player_x, 0)
	p.set_torch(torch)
	await get_tree().physics_frame

func _ready() -> void:
	run()

func run() -> void:
	await get_tree().process_frame
	var gm = GameManager
	await check_first_sight_line()
	gm._busy = true  # deaths flag is_dead but don't reload the scene mid-test
	# 1 blue band, dark: pause, then charge past you; hidden survives the pass
	await setup(2450, -1, 2450 - 12 - 230)
	await wait(0.2)
	ok(g.sight == EnemyGuard.Sight.BLUE, "blue band seen in the dark")
	ok(g.state == EnemyGuard.State.WAIT, "under threshold: no reaction yet")
	await wait(0.3)
	ok(g.state == EnemyGuard.State.NOTICE, "blue past threshold -> notice pause")
	p.is_hidden = true
	await wait(0.6)
	ok(g.state == EnemyGuard.State.CHARGE, "notice -> charge")
	await wait(1.6)
	ok(g.global_position.x < p.global_position.x - 100, "charges past where you were")
	ok(not p.is_dead, "hidden survives the charge passing")
	ok(g.is_alert(), "alert after a charge")
	# 2 outside the cone entirely, dark, 380 ahead: unseen
	await setup(2450, -1, 2450 - 12 - 380)
	await wait(0.2)
	ok(g.sight == EnemyGuard.Sight.NONE and g.state == EnemyGuard.State.WAIT, "beyond cone in dark is safe")
	# 3 lamp on 380 ahead: seen (blue)
	await setup(2450, -1, 2450 - 12 - 380, true)
	await wait(0.1)
	ok(g.sight == EnemyGuard.Sight.BLUE, "lamp on beyond the cone counts as blue")
	await wait(0.9)
	ok(g.state == EnemyGuard.State.CHARGE, "lit player starts a charge")
	# Move the target farther away during pursuit, then into the yellow band.
	# Neither change should cause another notice pause or a search stop.
	p.global_position.x = g.global_position.x - 280.0
	await wait(0.1)
	ok(g._target_x < p.global_position.x, "charge tracks the visible player's new position")
	p.global_position.x = g.global_position.x - 140.0
	var before_x: float = g.global_position.x
	await wait(0.1)
	ok(g.sight == EnemyGuard.Sight.YELLOW and g.state == EnemyGuard.State.CHARGE,
			"blue to yellow keeps the committed charge")
	ok(g.global_position.x < before_x - 20.0, "guard keeps running through yellow")
	# An open exit door must not leave him charging in place at the patrol end.
	await setup(2500, 1, 2890, true)
	p.facing = -1
	var exit_door = root_scene.get_node("PuzzlesAndHazards/ExitDoor")
	await wait(0.8)
	ok(g.sight == EnemyGuard.Sight.NONE and g.state == EnemyGuard.State.WAIT,
			"closed exit door blocks sight of the lit player")
	exit_door.open()
	await wait(1.3)
	ok(exit_door.is_open and exit_door._shape.disabled,
			"exit door has cleared the pursuit path")
	ok(g.state == EnemyGuard.State.NOTICE or g.state == EnemyGuard.State.CHARGE,
			"lamp beyond open exit door triggers pursuit")
	await wait(3.0)
	ok(p.is_dead, "guard reaches player beyond the door")
	await check_gate_trap()
	await setup(900, -1, 510, true)
	await wait(3.0)
	ok(p.is_dead, "guard reaches player past the light switch toward the entrance")
	# A missed charge returns to patrol facing the direction of travel.
	await setup(3000, 1, 0)
	g.state = EnemyGuard.State.WALK
	await wait(0.2)
	ok(g.global_position.x < 3000 and g.facing == -1,
			"outside patrol: returns without walking backwards")
	# 5 hidden in yellow: safe
	await setup(2450, -1, 2450 - 12 - 130)
	p.is_hidden = true
	await wait(0.3)
	ok(g.sight == EnemyGuard.Sight.NONE, "hidden is unseen")
	# 6 behind him: safe
	await setup(2450, -1, 2450 + 120, true)
	await wait(0.3)
	ok(g.sight == EnemyGuard.Sight.NONE, "behind him is unseen (even lamp on)")
	# 7 noise: goes to investigate, looks around, resumes patrol
	await setup(1500, 1, 900)
	g.state = EnemyGuard.State.WALK
	g.hear_noise(2450)
	await wait(0.2)
	ok(g.state == EnemyGuard.State.INVESTIGATE and g.is_alert(), "noise -> investigate, alert")
	await wait(7.5)
	ok(g.state == EnemyGuard.State.LOOK or g.state == EnemyGuard.State.WALK or g.state == EnemyGuard.State.WAIT, "investigate -> look -> patrol")
	ok(p.max_speed * p.sprint_mult > g.charge_speed, "sprint outruns the charge")
	# 9 god mode
	gm.set_god_level(1)
	await setup(2450, -1, 2450 - 12 - 120)
	await wait(1.5)
	ok(not p.is_dead, "god mode survives yellow")
	gm.set_god_level(0)
	# 4 yellow: under 1 s survives, ~1 s caught loses a life
	await setup(2450, -1, 2450 - 12 - 130)
	gm.set_checkpoint(Vector2(1080, 0))
	await wait(0.8)
	ok(g.sight == EnemyGuard.Sight.YELLOW, "yellow band detected")
	ok(not p.is_dead, "0.8 s in yellow survives")
	await wait(0.35)
	ok(p.is_dead, "~1 s in yellow catches you")
	ok(gm.has_checkpoint, "a guard catch can use the checkpoint while lives remain")
	# 8 (last: a death reloads the scene) touching him kills, hidden is safe
	await setup(2000, -1, 2000 + 20)
	p.is_hidden = true
	await wait(0.2)
	ok(not p.is_dead, "hidden overlapping him survives")
	await setup(2000, -1, 2000 + 20)
	gm.set_checkpoint(Vector2(1080, 0))
	await wait(0.1)
	ok(p.is_dead, "touching him from behind kills")
	ok(gm.has_checkpoint, "touch death keeps checkpoint")
	await check_shallow_pool()
	await check_lives()
	await check_guard_hints()
	print("RESULT %d/%d passed" % [checks - fails, checks])
	get_tree().quit(1 if fails else 0)


func check_shallow_pool() -> void:
	await setup(2410, -1, 2150)
	var pool: AcidPool = root_scene.get_node("PuzzlesAndHazards/ShallowAcidPool")
	var warnings: Array[float] = []
	pool.warning_started.connect(func(): warnings.append(g.global_position.x))
	p.is_hidden = true
	g.state = EnemyGuard.State.WALK
	await wait(0.25)
	ok(pool.state == AcidPool.State.IDLE, "entering the shallow pool does not immediately warn")
	await wait(0.65)
	ok(warnings.size() == 1 and g.global_position.x < warnings[0] - 22.0,
			"the guard's patrol triggers bubbling and he speeds up to clear the stalks")
	ok(not pool._warning_mark.visible, "a guard warning does not mark the player")
	await wait(0.35)
	ok(g.global_position.x < 2260.0 and g.state == EnemyGuard.State.WALK and pool.state == AcidPool.State.IDLE,
			"the guard clears the stalks and continues his patrol")

	await setup(2234, 1, 2196)
	pool = root_scene.get_node("PuzzlesAndHazards/ShallowAcidPool")
	await wait(0.15)
	ok(p.can_hide() and absf(p.global_position.y) < 1.0, "the edge of the alcove is a dry hiding spot")
	p.set_hidden(true)
	await wait(0.5)
	ok(pool.state == AcidPool.State.WARN and not pool._warning_mark.visible,
			"the stalk beside the alcove warns the guard while the hidden player is safe")
	await wait(2.0)
	ok(p.is_hidden and not p.is_dead and p.acid_pool == null, "hiding beside the stalk stays safe through the warning")

	await setup(900, -1, 1640)
	pool = root_scene.get_node("PuzzlesAndHazards/ShallowAcidPool")
	GameManager._busy = false
	Input.action_press("ui_right")
	await wait(3.7)
	Input.action_release("ui_right")
	GameManager._busy = true
	ok(p.global_position.x > 2478.0 and p.acid_pool == null and not p.is_dead and pool.state == AcidPool.State.IDLE,
			"the player can walk through with the lamp off")

	await setup(2465, 1, 2228)
	pool = root_scene.get_node("PuzzlesAndHazards/ShallowAcidPool")
	GameManager._busy = false
	GameManager._set_lives(GameManager.MAX_LIVES)
	await wait(0.85)
	ok(pool.state == AcidPool.State.WARN and pool._warning_mark.visible, "lingering over the stalks warns the player")
	ok(is_equal_approx(g.global_position.x, 2465.0), "the guard stays put outside the strike's reach")
	await wait(1.5)
	ok(not p.is_dead and GameManager.lives == 2 and absf(p.global_position.x - 2150.0) < 2.0,
			"the shallow stalks spend a heart and put the player on the alcove ledge")


func check_lives() -> void:
	root_scene.queue_free()
	await get_tree().process_frame
	GameManager._busy = false
	# Keep this runner alive while the real chamber reloads.
	get_tree().current_scene = null
	await GameManager.go_to_chamber(CHAMBER)
	var room: Node = get_tree().current_scene
	var player: Player = room.get_node("Player")
	player.global_position.x = 835.0
	await wait(0.12)
	ok(GameManager.has_checkpoint, "walking past the entry vent saves the grille checkpoint")
	var lives_seen: Array[int] = []
	var track_lives := func(remaining: int) -> void: lives_seen.append(remaining)
	GameManager.lives_changed.connect(track_lives)
	for remaining: int in [2, 1, 0]:
		player.kill()
		player.kill()
		while GameManager.is_transitioning():
			await get_tree().process_frame
		room = get_tree().current_scene
		player = room.get_node("Player")
		if remaining > 0:
			var hearts: HBoxContainer = room.get_node("HUD/HUD/Lives")
			ok(GameManager.lives == remaining and not hearts.get_child(remaining).filled
					and hearts.get_child(remaining - 1).filled, "HUD shows %d filled hearts after respawn" % remaining)
			ok(absf(player.global_position.x - 835.0) < 2.0, "retry starts at the saved checkpoint")
			if remaining == 2:
				await GameManager.respawn_player()
				player = get_tree().current_scene.get_node("Player")
				ok(GameManager.lives == 2, "manual restart does not spend or restore a life")
		else:
			ok(GameManager.lives == 3 and not GameManager.has_checkpoint and absf(player.global_position.x) < 2.0,
					"third death restarts the chamber with three lives")
	ok(lives_seen == [2, 1, 0, 3], "each death spends one life and the HUD can show the empty row")
	GameManager.lives_changed.disconnect(track_lives)
	player.kill()
	while GameManager.is_transitioning():
		await get_tree().process_frame
	await GameManager.go_to_chamber(CHAMBER)
	ok(GameManager.lives == 3, "entering a chamber replenishes lives")


func check_first_sight_line() -> void:
	await setup(2350, 1, 900)
	var camera: Camera2D = root_scene.get_node("MainCamera")
	camera.global_position.x = 900.0
	camera.reset_smoothing()
	await wait(0.1)
	ok(p.get_node_or_null("PlayerSpeech") == null, "the player says nothing while the guard is offscreen")
	g.global_position.x = 1410.0
	await wait(0.25)
	var bubble: PanelContainer = p.get_node_or_null("PlayerSpeech")
	ok(bubble != null and p.controls_enabled, "seeing the first guard prompts the player without locking controls")
	await setup(1410, 1, 900)
	await wait(0.6)
	ok(p.get_node_or_null("PlayerSpeech") == null, "the first guard line plays once across reloads")


func check_gate_trap() -> void:
	await setup(1200, -1, 900)
	var gate: LockedDoor = root_scene.get_node("PuzzlesAndHazards/Door")
	var plate: FloorSwitch = root_scene.get_node("PuzzlesAndHazards/FloorSwitch")
	g._player = p
	ok(g._has_line_of_sight(g._lantern_global(), p.global_position + Vector2(0, -50)),
			"the closed grille lets him see the player")
	await wait(1.7)
	ok(g.state == EnemyGuard.State.CHARGE and g.global_position.x > gate.global_position.x and not p.is_dead,
			"the closed grille stops the guard's charge")
	plate.charge = 0.0
	p.set_torch(true)
	for tick: int in 165:
		await get_tree().physics_frame
		if g.global_position.x < gate.global_position.x:
			break
	ok(gate.is_open and g.global_position.x < gate.global_position.x, "the lamp raises the grille and the guard crosses")
	p.is_hidden = true
	p.global_position.x = 1210.0
	p.set_torch(false)
	await wait(3.8)
	ok(not gate.is_open and g.global_position.x < gate.global_position.x, "the drained plate shuts the grille and traps him")
	p.is_hidden = false
	p.global_position.x = gate.global_position.x + 45.0
	await wait(1.4)
	ok(g.sight == EnemyGuard.Sight.BLUE and not p.is_dead and g.global_position.x < gate.global_position.x,
			"across the dropped grille, he can spot the player but cannot catch him")
	g.set_physics_process(false)
	p.set_physics_process(false)
	for tick: int in 12:
		await get_tree().physics_frame
		p.move_and_collide(Vector2(-4.0, 0.0))
	ok(p.global_position.x > gate.global_position.x + gate.width * 0.5,
			"the closed grille also blocks the player")
	g.global_position.x = gate.global_position.x + 10.0
	gate.open()
	await wait(1.7)
	gate.close()
	await wait(0.65)
	ok(g.global_position.x >= gate.global_position.x + gate.width * 0.5 + EnemyGuard.BODY_HALF_WIDTH,
			"the descending grille leaves a guard in the doorway on his own side")


func check_guard_hints() -> void:
	GameManager.clear_checkpoint()
	GameManager.set_death_line("")
	var hints: Array[String] = []
	GameManager.respawn_hint.connect(func(line: String) -> void: hints.append(line))
	for lamp_on: bool in [false, true]:
		GameManager.reset_death_hints()
		hints.clear()
		for attempt: int in 3:
			var scene: Node = get_tree().current_scene
			var player: Player = scene.get_node("Player")
			var guard: EnemyGuard = scene.get_node("PuzzlesAndHazards/Guard")
			player.global_position = Vector2(guard.global_position.x - 120.0, 0.0)
			player.set_torch(lamp_on)
			await wait(1.3)
			while GameManager.is_transitioning():
				await get_tree().process_frame
			if attempt < 2:
				ok(hints.is_empty(), "guard death %d gives no early hint (lamp %s)" % [attempt + 1, lamp_on])
		var expected: String = GameManager.GUARD_LAMP_HINT if lamp_on else GameManager.GUARD_HINT
		ok(hints == [expected], "guard gives the matching hint after three catches (lamp %s)" % lamp_on)
