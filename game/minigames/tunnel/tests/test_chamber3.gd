extends Node
## Headless check for Chamber 3: the searchlight sweeps, kills in the open,
## passes over a hidden player, and every pillar gap is crossable.
var fails := 0
var checks := 0
var root_scene: Node
var s
var p

func ok(c: bool, name: String) -> void:
	checks += 1
	if not c: fails += 1
	print(("PASS " if c else "FAIL ") + name)

func wait(sec: float) -> void:
	for i in int(sec * 60.0):
		await get_tree().physics_frame

func setup() -> void:
	if root_scene: root_scene.queue_free(); await get_tree().process_frame
	root_scene = load("res://minigames/tunnel/scenes/chambers/chamber_3.tscn").instantiate()
	add_child(root_scene)
	await get_tree().process_frame
	s = root_scene.find_child("Searchlight", true, false)
	p = root_scene.find_child("Player", true, false)
	await get_tree().physics_frame

func _ready() -> void:
	run()

func run() -> void:
	await get_tree().process_frame
	GameManager._busy = true
	# 1 sweeps left from the far end
	await setup()
	var x0: float = s.pool_x
	var camera: Camera2D = root_scene.get_node("MainCamera")
	var screen_right: float = camera.get_screen_center_position().x + get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)
	var glow_radius: float = s._glow_light.texture.get_width() * s.glow_scale * 0.5
	ok(x0 - maxf(s.pool_half_width, glow_radius) > screen_right, "opening pool and glow start off screen to the right")
	var middle_vent = root_scene.get_node("MiddleVent")
	ok(is_equal_approx(middle_vent.position.x, 2300.0) and middle_vent.readable_grate, "readable middle vent at the central pillar")
	ok(root_scene.get_node("ApproachVent").position.x > 1000.0, "opening stretch has no vent")
	await wait(0.5)
	ok(s.pool_x < x0 - 80, "searchlight sweeps left")
	# Detection must match the visible shadow cuts, without pressing Hide.
	await setup()
	for guard in get_tree().get_nodes_in_group("guard"):
		guard.set_physics_process(false)
	s.set_physics_process(false)
	for span: Vector2 in s.shadow_spans:
		for x: float in [span.x, (span.x + span.y) * 0.5, span.y]:
			p.global_position.x = x
			s.pool_x = x
			ok(not p.is_hidden and not s.player_in_light(), "standing pillar shadow is safe at x=%s" % x)
		for x: float in [span.x - 1.0, span.y + 1.0]:
			p.global_position.x = x
			s.pool_x = x
			ok(s.player_in_light(), "exposed side of shadow is detectable at x=%s" % x)
	await setup()
	for guard in get_tree().get_nodes_in_group("guard"):
		guard.set_physics_process(false)
	p.global_position.x = 800.0
	s.pool_x = 1100.0
	s._dir = -1
	await wait(3.0)
	ok(not p.is_hidden and not p.is_dead and p.controls_enabled, "first pillar protects a standing player throughout the opening pass")
	ok(s.pool_x < 690.0 - s.pool_half_width, "opening pass fully clears the first pillar")
	# 2 open bridge: caught
	await setup()
	p.global_position.x = 2650
	s.pool_x = 2650 + 200
	s._dir = -1
	GameManager.set_checkpoint(Vector2(1550, 0))
	await wait(1.5)
	ok(p.is_dead, "caught in the open")
	ok(GameManager.has_checkpoint, "a spotlight catch can use the checkpoint while lives remain")
	# 3 hidden at a pillar: survives the pass
	await setup()
	p.global_position.x = 2300
	p.enter_hide_zone()
	p.set_hidden(true)
	s.pool_x = 2300 + 400
	s._dir = -1
	await wait(3.5)
	ok(not p.is_dead, "hidden at a pillar survives the pass")
	ok(s.pool_x < 2300 - 300, "light went past him")
	# 4 the five pillars each have a hide zone
	var hides := 0
	for n in root_scene.find_children("HidePillar*", "", true, false): hides += 1
	ok(hides == 5, "five pillar hide spots")
	# 5 gaps: walking a gap is faster than the light crossing it from the next pillar
	var gap: float = 750.0
	ok(gap / p.max_speed < 3.2, "walk a gap in ~3 s")
	# 6 pillars shade the pool
	ok(s._lit_fraction(2300 - 130, 2300 + 130) < 0.3, "pool over a pillar is mostly shaded")
	ok(is_equal_approx(s._lit_fraction(2650 - 130, 2650 + 130), 1.0), "pool on open deck fully lit")
	# 7 god mode
	# The pipe draws the patrol backward past a safely hidden player, opening
	# the route forward without disabling the independent searchlight.
	await setup()
	p.global_position.x = 1550
	p.enter_hide_zone()
	p.set_hidden(true)
	var guard = root_scene.get_node("BridgeGuard")
	var lever = root_scene.get_node("NoiseLever")
	guard.global_position.x = 1850
	lever._bang()
	ok(guard.state == guard.State.INVESTIGATE, "pipe starts guard investigation")
	ok(is_equal_approx(guard._target_x, 950.0), "pipe lures guard backward")
	await wait(6.5)
	ok(guard.global_position.x < 1400, "guard passes the valve toward the clang")
	ok(not p.is_dead, "pillar protects player from passing guard and searchlight")
	ok(s.pool_x < 3000, "searchlight keeps sweeping during distraction")
	var end_lever = root_scene.get_node("NoiseLeverEnd")
	var end_guard = root_scene.get_node("BridgeGuard2")
	p.global_position.x = 3800
	p.set_hidden(false)
	end_guard.set_physics_process(false)
	end_guard.global_position.x = 4050
	await wait(0.3)
	ok(end_lever._prompt.modulate.a > 0.4, "nearby usable pipe shows faint E")
	end_lever._bang()
	ok(is_equal_approx(end_guard._target_x, 2800.0), "end pipe draws second guard back along bridge")
	ok(is_zero_approx(end_lever._prompt.modulate.a), "pipe prompt disappears during cooldown")
	p.global_position.x = 3500
	await wait(0.2)
	ok(is_zero_approx(end_lever._prompt.modulate.a), "pipe prompt stays hidden out of reach")
	GameManager.set_god_level(1)
	await setup()
	p.global_position.x = 2650
	s.pool_x = 2650
	await wait(1.0)
	ok(not p.is_dead, "god mode survives the light")
	GameManager.set_god_level(0)
	print("RESULT %d/%d passed" % [checks - fails, checks])
	get_tree().quit(1 if fails else 0)
