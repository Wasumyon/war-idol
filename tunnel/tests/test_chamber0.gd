extends Node
## Headless check for Room 0 (the fall): he falls with controls off, the vent worms
## knock ahead of him and strike only after he's past, he lands safely, gets up,
## the lamp hint shows, the lamp turns on, and the exit leads on to Chamber 1.
## Set SHOTS=<dir> to also save screenshots.
var fails := 0
var checks := 0
var shots := OS.get_environment("SHOTS")

func ok(c: bool, name: String) -> void:
	checks += 1
	if not c: fails += 1
	print(("PASS " if c else "FAIL ") + name)

func shot(name: String) -> void:
	if shots == "": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))

func _ready() -> void:
	run()

func run() -> void:
	await get_tree().process_frame
	var sc: Node = load("res://scenes/chambers/chamber_0.tscn").instantiate()
	add_child(sc)
	await get_tree().process_frame
	var p: Player = sc.find_child("Player", true, false)
	var worms: Array = get_tree().get_nodes_in_group("vent_worms")
	var lungers: Array = get_tree().get_nodes_in_group("vent_lungers")
	var lunged_behind := true
	var lunge_shots := 0
	var lunge_max := {}
	ok(not p.controls_enabled, "falling: controls off")
	var struck_above := true
	var max_reach_miss := 1e9
	var landed_t := -1.0
	var t := 0.0
	var shot_strike := false
	var knocked_before_strike := true
	var seen_fall_anim := false
	var seen_brace := false
	var seen_landing := false
	var seen_recovery := false
	var saw_landing_line := false
	var impact_shake: float = 0.0
	var unlock_time: float = -1.0
	var fall_frames: Dictionary = {}
	var sprite: AnimatedSprite2D = p.get_node("Visual/Body/Sprite")
	var camera: Camera2D = sc.get_node("MainCamera")
	while t < 9.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if sprite.animation == &"fall":
			seen_fall_anim = true
			fall_frames[sprite.frame] = true
		if sprite.animation == &"fall_brace" and not p.is_on_floor(): seen_brace = true
		if sprite.animation == &"hide" and p.is_on_floor(): seen_landing = true
		if sprite.animation == &"fall_recover" and not p.controls_enabled: seen_recovery = true
		if p.is_on_floor():
			impact_shake = maxf(impact_shake, absf(camera.offset.y))
			if p.get_node_or_null("PlayerSpeech"):
				saw_landing_line = true
			if p.controls_enabled and unlock_time < 0.0:
				unlock_time = t
		for w in worms:
			if w.growth > 0.5:
				# a striking worm must be above his head
				if p.global_position.y - 110.0 < w.global_position.y: struck_above = false
		for l in lungers:
			lunge_max[l] = maxf(lunge_max.get(l, 0.0), l.extension)
			if l.extension > 0.5 and p.global_position.y < l.global_position.y + 60.0:
				lunged_behind = false
			if l.extension > 0.95 and lunge_shots < 2 and l == lungers[lunge_shots * 3]:
				lunge_shots += 1
				await shot("room0_lunge_%d" % lunge_shots)
		if not shot_strike:
			for w in worms:
				if w.growth > 0.9:
					shot_strike = true
					await shot("room0_2_strike")
		if absf(t - 0.8) < 0.01: await shot("room0_1_falling")
		if landed_t < 0.0 and p.is_on_floor():
			landed_t = t
	ok(seen_fall_anim, "fall animation played")
	ok(fall_frames.size() == 1, "the airborne crouch holds steady until the brace")
	ok(seen_brace and seen_landing and seen_recovery, "airborne brace flows into the landing crouch and recovery")
	ok(impact_shake >= 30.0, "the camera jolts on impact")
	ok(unlock_time - landed_t > 1.15 and unlock_time - landed_t < 1.5, "the landing briefly locks movement")
	ok(saw_landing_line, "the player speaks after landing")
	ok(landed_t > 3.0 and landed_t < 8.0, "landed after a few seconds (%.1f s)" % landed_t)
	ok(struck_above, "every worm struck behind (above) him, never at him")
	ok(lunged_behind, "every lunger burst out only after he was past it")
	var lunged := 0
	for l in lungers:
		if lunge_max.get(l, 0.0) > 0.95: lunged += 1
	ok(lungers.size() == 4 and lunged == 4, "all 4 back-wall lungers lunged at the camera (%d)" % lunged)
	var struck := 0
	for w in worms:
		if w.growth > 0.5: struck += 1
	ok(struck == worms.size(), "all %d worm clusters struck" % worms.size())
	ok(not p.is_dead, "fall is safe")
	ok(p.controls_enabled, "got up: controls back")
	ok(p.anim_override == &"", "standing")
	var menu_key: Label = sc.get_node("ControlsSign/Menu")
	ok(menu_key.is_visible_in_tree() and menu_key.text == "Esc: Menu", "wall sign lists the pause key")
	await get_tree().create_timer(0.1).timeout
	var prompt: Label = p.get_node("ActionPrompt")
	await get_tree().create_timer(0.7).timeout
	ok(not prompt.visible, "no overhead prompt at landing")
	await shot("room0_3_dark")
	p.set_torch(true)
	await get_tree().create_timer(0.5).timeout
	ok(p.is_torch_on, "lamp on")
	await shot("room0_4_lamp")
	p.walk_to(900)
	await p.walk_arrived
	await shot("room0_5_tunnel")
	p.walk_to(1700)
	var went := false
	for i in 400:
		await get_tree().physics_frame
		if GameManager.is_transitioning(): went = true; break
	ok(went, "exit leads on (Chamber 1)")
	print("RESULT %d/%d passed" % [checks - fails, checks])
	get_tree().quit(1 if fails else 0)
