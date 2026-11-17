extends Node
## Headless check for Chamber 4: two catwalk guards whose floor pools hold the
## tubeworms back. Fringe safe, core and a lamp he can see catch you (chamber
## restart). The short middle bed and the ledge past B's bulkhead are never
## watched or lit. A scripted run can cross the whole chamber.
var fails := 0
var checks := 0
var root_scene: Node
var ga
var gb
var p

func ok(c: bool, name: String) -> void:
	checks += 1
	if not c: fails += 1
	print(("PASS " if c else "FAIL ") + name)

func wait(sec: float) -> void:
	for i in int(sec * 60.0):
		await get_tree().physics_frame

func setup() -> void:
	if root_scene:
		root_scene.queue_free()
		await get_tree().process_frame
	GameManager.clear_checkpoint()
	root_scene = load("res://minigames/tunnel/scenes/chambers/chamber_4.tscn").instantiate()
	add_child(root_scene)
	await get_tree().process_frame
	ga = root_scene.find_child("GuardA", true, false)
	gb = root_scene.find_child("GuardB", true, false)
	p = root_scene.find_child("Player", true, false)
	await get_tree().physics_frame

func put_guard(g, x: float, dir: int) -> void:
	g.place(x, dir)

func worm_near(x: float):
	var best = null
	for w in root_scene.find_children("Worms*", "", true, false):
		if best == null or absf(w.global_position.x - x) < absf(best.global_position.x - x):
			best = w
	return best

func _ready() -> void:
	run()

func run() -> void:
	await get_tree().process_frame
	GameManager._busy = true

	# 1 two guards
	await setup()
	ok(ga != null and gb != null, "two guards")
	var x0: float = ga.pool_x
	await wait(1.0)
	ok(ga.pool_x > x0 + 80, "guard A's pool slides along bed 1")

	# 2 over 60 s of patrol, no pool ever lights the middle bed or the end ledge
	await setup()
	p.global_position = Vector2(-200, 0)  # out of the way
	var mid_lit := false
	var end_lit := false
	var gap_lit := false
	for i in 3600:
		await get_tree().physics_frame
		for g in [ga, gb]:
			var span: Vector2 = g.lit_span()
			var l: float = span.x
			var r: float = span.y
			# the stone between a bed and its pillar stays dark
			if r > l and ((r > 1190.0 and l < 1360.0) or (r > 1610.0 and l < 1805.0)): gap_lit = true
			if r > 1400.0 and l < 1570.0: mid_lit = true
			if r > 2640.0: end_lit = true
	ok(not mid_lit, "no light ever reaches the middle bed")
	ok(not end_lit, "no light ever reaches the end ledge")
	ok(not gap_lit, "no light ever reaches the stone by a pillar")

	# 3 middle bed: lamp on, nobody sees you
	await setup()
	p.global_position = Vector2(1260, 0)
	p.set_torch(true)
	await wait(0.6)
	var t := 0.0
	while t < 20.0 and not p.is_dead:
		p.global_position.x = 1300.0 + 300.0 * (0.5 + 0.5 * sin(t))
		await get_tree().physics_frame
		t += 1.0 / 60.0
	ok(not p.is_dead, "lamp in the middle bed: unseen and worms held back (20 s)")

	# 4 end ledge: lamp on, safe
	await setup()
	p.global_position = Vector2(2800, 0)
	p.set_torch(true)
	await wait(20.0)
	ok(not p.is_dead, "end ledge is safe, lamp on (20 s)")

	# 5 grown worms kill in the dark
	await setup()
	p.global_position = Vector2(2100, 0)
	put_guard(gb, 2290, 1)
	gb.walk_speed = 0.0
	put_guard(ga, 350, 1)
	ga.walk_speed = 0.0
	p.global_position = Vector2(1880, 0)
	await wait(0.5)
	ok(p.is_dead, "grown worms kill")

	# 6 fringe safe, core catches, chamber restarts
	await setup()
	put_guard(ga, 600, 1)
	ga.walk_speed = 0.0
	await wait(0.8)
	ga.walk_speed = 120.0
	var alive := true
	for i in 180:
		p.global_position = Vector2(ga.pool_x - 140, 0)
		await get_tree().physics_frame
		if p.is_dead: alive = false
	ok(alive, "the dim fringe is safe while he walks")
	await setup()
	put_guard(ga, 600, 1)
	ga.walk_speed = 0.0
	await wait(0.8)
	p.global_position = Vector2(ga.pool_x, 0)
	await wait(0.9)
	ok(not p.is_dead and not p.controls_enabled, "core: he has you, frozen for the shout")
	ok(GameManager._death_line in ga.shot_lines, "core: he shouts a fire line")
	await wait(1.0)
	ok(not p.is_dead, "a beat between the shout and the shot")
	await wait(0.8)
	ok(p.is_dead, "the bright core: shot")

	# 7 lamp seen in front, safe behind his back
	await setup()
	put_guard(gb, 1990, 1)
	gb.walk_speed = 0.0
	await wait(0.8)
	p.global_position = Vector2(2290, 0)
	await wait(0.3)
	# Beam pointed away from him (cone lamp), out of spill range: he doesn't see it.
	p.facing = 1
	p.set_torch(true)
	await wait(0.6)
	ok(not gb.is_suspicious(), "cone lamp pointed away from him: unseen")
	p.set_torch(false)
	await wait(1.5)
	p.facing = -1  # now pointing it at him
	p.set_torch(true)
	var pool0: float = gb.pool_x
	await wait(0.5)
	ok(gb.is_suspicious() and gb.pool_x > pool0 + 60, "lamp seen: '?' and his beam slides toward it")
	ok(not p.is_dead, "the '?' stage doesn't kill")
	await wait(2.4)
	ok(p.is_dead, "lamp kept on: shot")
	# near miss: lamp off during the '?' and he loses you
	await setup()
	put_guard(gb, 1990, 1)
	gb.walk_speed = 0.0
	put_guard(ga, 350, 1)
	await wait(0.8)
	p.global_position = Vector2(gb.pool_x + 150, 0)  # front fringe, worms down
	await wait(0.2)
	p.set_torch(true)
	await wait(0.5)
	p.set_torch(false)
	await wait(2.5)
	ok(not p.is_dead, "near miss: lamp off during the '?' and he loses you")
	ok(not gb.is_suspicious() and absf(gb._slide) < 5.0, "his beam drifts back after losing you")
	await setup()
	put_guard(gb, 2250, 1)
	gb.walk_speed = 0.0
	await wait(0.8)  # light the spot first so the worms are down
	p.global_position = Vector2(2380, 0)
	p.set_torch(true)
	put_guard(gb, 2250, -1)
	await wait(1.5)
	ok(not p.is_dead, "lamp behind his back is safe")

	# 8 turning doesn't grant immunity to the bright core
	await setup()
	put_guard(gb, 2290, 1)
	gb.walk_speed = 0.0
	await wait(0.8)
	gb.walk_speed = 120.0
	gb.state = gb.State.WAIT
	gb._wait_timer = 0.3
	p.global_position = Vector2(-200, 0)
	await wait(0.35)
	for i in 42:
		p.global_position = Vector2(gb.pool_x, 0)
		await get_tree().physics_frame
	ok(gb.state == gb.State.SHOOT, "the core catches during the turn (lamp off)")

	# 9 pillars are hide spots and out of sight
	await setup()
	for x in [1260.0, 1710.0]:
		p.global_position = Vector2(x, 0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		ok(p.can_hide(), "hide spot at pillar %d" % int(x))

	# 10 full run, scripted: ride A's trailing fringe, lamp across the gap,
	# wait at pillar 2 for B, ride his trailing fringe, lamp behind his back.
	await setup()
	t = 0.0
	var phase := 0
	var reached := false
	while t < 120.0 and not p.is_dead:
		var x: float = p.global_position.x
		var target: float = x
		var lamp := false
		match phase:
			0:  # ride A
				if ga.facing > 0 and ga.state == ga.State.WALK:
					target = maxf(x, ga.pool_x - 150.0)
				elif ga.facing < 0 and ga.state == ga.State.WALK and x - ga.global_position.x > 60.0:
					target = 1260.0; lamp = true
				if x >= 1250.0: phase = 1
			1:  # the gap
				target = 1710.0; lamp = true
				if x >= 1700.0: phase = 2
			2:  # wait for B to turn right at his left end
				if gb.facing > 0 and gb.state == gb.State.WALK and gb.global_position.x < 2000.0:
					phase = 3
			3:  # ride B
				if gb.facing > 0 and gb.state == gb.State.WALK:
					target = maxf(x, gb.pool_x - 150.0)
				elif gb.facing < 0 and gb.state == gb.State.WALK and x - gb.global_position.x > 60.0:
					target = 3060.0; lamp = true
		if p.is_torch_on != lamp: p.set_torch(lamp)
		p.global_position.x = move_toward(x, target, 250.0 / 60.0)
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if p.global_position.x >= 3040.0:
			reached = true
			break
	ok(reached and not p.is_dead, "full scripted run reaches the exit (%.1f s, phase %d, x %d)" % [t, phase, int(p.global_position.x)])

	var ex = root_scene.find_child("Exit", true, false)
	ok(ex.next_scene == "res://minigames/tunnel/scenes/chambers/chamber_5.tscn", "exit leads to chamber 5")
	ok(root_scene.find_children("Checkpoint*", "", true, false).is_empty(), "no checkpoints")

	print("%d/%d passed" % [checks - fails, checks])
	get_tree().quit(1 if fails else 0)
