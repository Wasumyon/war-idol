extends Node
## Run with --headless --fixed-fps 60 --path game res://tests/stealth_smoke.tscn.
## Plays the stealth test map through its rules with synthetic input. Must print 0 failures.
## Set STEALTH_SHOTS to a folder and run without --headless to also save screenshots.

const STEALTH := preload("res://minigames/stealth/stealth.tscn")

var _failures := 0
var _s: Node
var _result := {}
var _shots := OS.get_environment("STEALTH_SHOTS")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# A script error must not leave the run hanging: give up after 10 simulated minutes.
	get_tree().create_timer(600.0).timeout.connect(func() -> void:
		print("stealth smoke: timed out")
		get_tree().quit(2))
	_s = STEALTH.instantiate()
	if not _s.has_method(&"begin"):
		print("stealth smoke: the segment root failed to load")
		get_tree().quit(2)
		return
	_s.begin({"map": "test_map"})
	_s.finished.connect(func(result: Dictionary) -> void: _result = result)
	add_child(_s)
	await _frames(20)
	_guards_run(false)
	await _movement()
	await _senses()
	await _hiding()
	await _noise()
	await _alarm()
	await _exit()
	print("stealth smoke: %d failures" % _failures)
	get_tree().quit(1 if _failures else 0)


func _movement() -> void:
	var p: CharacterBody3D = _s.player
	_check(_s.map.name == &"TestMap", "the map named in args is loaded")
	_check(p.is_on_floor() and absf(p.global_position.y) < 0.05, "the player stands on the ground")
	await _shot("1_iso_start")

	var from := p.global_position
	await _walk_for(Vector3(1, 0, 0), 30)
	var walked := p.global_position.x - from.x
	_check(walked > 1.5, "WASD moves the player (%.2f m in half a second)" % walked)
	_check(p.footstep_radius() == p.walk_noise_radius, "walking makes full footstep noise")

	Input.action_press(&"stealth_crouch")
	from = p.global_position
	await _walk_for(Vector3(0, 0, 1), 30)
	var crept := p.global_position.z - from.z
	_check(p.crouched and crept > 0.4 and crept < walked * 0.6, "crouching is slower (%.2f m)" % crept)
	_check(p.footstep_radius() == p.crouch_noise_radius, "crouching shrinks the footsteps")
	Input.action_release(&"stealth_crouch")
	await _frames(5)
	_check(not p.crouched and p.footstep_radius() == 0.0, "standing still is silent")

	var rig: Node3D = _s.get_node("CameraRig")
	_check(is_equal_approx(rig.yaw(), deg_to_rad(45.0)), "the camera starts isometric")
	_press(&"stealth_camera")
	await _frames(45)
	_check(rig.preset == rig.Preset.TOP_DOWN and is_zero_approx(rig.yaw()), "V switches to top-down")
	from = p.global_position
	await _walk_for(Vector3(0, 0, -1), 20)
	_check(p.global_position.z < from.z - 0.8, "W is up the screen in top-down")
	await _shot("2_top_down")
	_press(&"stealth_camera")
	await _frames(45)
	_check(rig.preset == rig.Preset.ISOMETRIC, "V switches back")

	# Behind the south wall, seen from the isometric camera.
	p.teleport(Vector3(-14, 0, 13.2))
	await _frames(30)
	var wall: Node = _s.map.get_node("Blocks/WallSouth")
	_check(wall._faded, "a wall between camera and player fades")
	await _shot("3_wall_fade")
	p.teleport(Vector3(-14, 0, 8))
	await _frames(30)
	_check(not wall._faded, "and comes back when he steps away")

	p.teleport(Vector3(-3.5, 0, -3))
	await _frames(5)
	await _walk_to(Vector3(-3.5, 2, -10.5), 400)
	_check(absf(p.global_position.y - 2.0) < 0.1 and p.is_on_floor(),
		"the ramp leads up onto the platform (y %.2f)" % p.global_position.y)
	await _shot("4_platform")


func _exit() -> void:
	var p: CharacterBody3D = _s.player
	p.teleport(Vector3(10.5, 0, -2))
	await _frames(3)
	_check(_s._checkpoint_pos.is_equal_approx(Vector3(10.5, 0, -2)), "stepping on the checkpoint takes it")
	_check(_result.is_empty(), "no result before the exit")
	p.teleport(Vector3(16, 0, 12))
	await _frames(3)
	_check(_result.get("outcome") == "loud" and _result.get("alarms") == 2
		and _result.get("catches") == 1, "reaching the exit emits finished: %s" % [_result])
	await _shot("9_exit")


func _senses() -> void:
	var p: CharacterBody3D = _s.player
	var g: CharacterBody3D = _s.map.get_node("Guards/EastSentry")
	var dt := 1.0 / 60.0
	_check(_s.map.guards.size() == 4, "the map's four guards are collected")
	_check(g.state == g.State.PATROL and g.meter == 0.0, "guards start on patrol")

	# The sentry stands at (13, 9) looking west; the tests turn him by hand.
	g.rotation.y = PI / 2
	await _place(Vector3(9.5, 0, 9))
	_check(g.can_see(p), "a guard sees the player in his cone")
	await _place(Vector3(16, 0, 9))
	_check(not g.can_see(p), "not behind his back")
	await _place(Vector3(6, 0, 9))
	_check(not g.can_see(p), "not through a wall")
	g.rotation.y = 0.0
	await _place(Vector3(12, 0, 2.5))
	_check(g.can_see(p), "low cover does not hide him standing")
	Input.action_press(&"stealth_crouch")
	await _frames(3)
	_check(not g.can_see(p), "low cover hides him crouched")
	Input.action_release(&"stealth_crouch")
	await _frames(3)

	await _place(Vector3(13.3, 0, 7))
	g.meter = 0.0
	for i in 6:
		g._sense(dt)
	var near: float = g.meter
	await _place(Vector3(14, 0, 1))
	g.meter = 0.0
	g._set_state(g.State.PATROL)
	for i in 6:
		g._sense(dt)
	var far: float = g.meter
	_check(far > 0.0 and near > far * 2.0,
		"the meter fills faster up close (%.3f against %.3f)" % [near, far])
	_s.crisis_level = 2
	g.meter = 0.0
	for i in 6:
		g._sense(dt)
	_check(g.meter > far * 1.5, "and faster at a higher crisis level (%.3f)" % g.meter)
	_s.crisis_level = 0
	await _place(Vector3(13, 0, 12))
	var full: float = g.meter
	for i in 90:
		g._sense(dt)
	_check(g.meter < full, "it drains when he is not noticed (%.2f to %.2f)" % [full, g.meter])

	# Footsteps 3 m behind him.
	g.meter = 0.0
	g._set_state(g.State.PATROL)
	_steer(Vector3(1, 0, 0))
	await _frames(10)
	_check(not g.can_see(p) and g.can_hear(p), "walking behind him is heard")
	g._sense(dt)
	_check(g.meter > 0.0, "and fills the meter")
	Input.action_press(&"stealth_crouch")
	await _frames(10)
	_check(not g.can_hear(p), "crouch-walking at that distance is not")
	_steer(Vector3.ZERO)
	Input.action_release(&"stealth_crouch")
	await _frames(5)
	g.meter = 0.0

	# The overlay setting: one place decides what is drawn.
	_check(_s.overlay_level() == g.Overlay.FACING, "by default real time shows facing only")
	g.redraw()
	_check(not g._hearing.visible and g._cone_mesh.get_surface_count() == 1,
		"so the hearing ring is hidden and only the marker is drawn")
	_s.overlay_mode = _s.OverlayMode.AIM_ONLY
	g.redraw()
	_check(g._cone_mesh.get_surface_count() == 0, "aim_only draws nothing in real time")
	_press(&"stealth_overlay_view")
	await _frames(3)
	_check(_s.overlay_view and _s.overlay_level() == g.Overlay.FULL and g._hearing.visible,
		"Q opens the overlay view with everything shown")
	var before := p.global_position
	_steer(Vector3(-1, 0, 0))
	await _frames(10)
	_steer(Vector3.ZERO)
	_check(p.global_position.is_equal_approx(before), "and the world is stopped")
	await _shot("5_overlay_view")
	_press(&"stealth_overlay_view")
	await _frames(3)
	_guards_run(false)
	_s.overlay_mode = _s.OverlayMode.ALWAYS
	_check(_s.overlay_level() == g.Overlay.FULL, "always shows cones in real time")
	_s.overlay_mode = _s.OverlayMode.FACING


func _hiding() -> void:
	var p: CharacterBody3D = _s.player
	var g: CharacterBody3D = _s.map.get_node("Guards/Platform")

	# Concealment: the guard stands north of the steam vent, looking at it.
	g.global_position = Vector3(-1, 0, 4)
	g.rotation.y = PI
	await _place(Vector3(2, 0, 9))
	_check(g.can_see(p), "beside the concealment patch he is seen")
	await _place(Vector3(-1, 0, 9))
	_check(not g.can_see(p) and _s.is_concealed(p.global_position), "inside it he is hidden")
	await _shot("7_concealed")

	# Height: the player on the platform, the guard at the foot of the ramp.
	g.global_position = Vector3(-3.5, 0, -3)
	g.rotation.y = 0.0
	await _place(Vector3(-3.5, 2, -10.5))
	_check(not g.can_see(p), "on high ground he is hidden from a guard below")
	g._set_state(g.State.ALARMED)
	_check(not g.can_see(p), "even an alerted one")
	g._set_state(g.State.PATROL)

	# The guard on the platform, the player on the yard floor below.
	g.global_position = Vector3(-3.5, 2, -9)
	g.rotation.y = PI
	await _place(Vector3(-0.5, 0, -3))
	_check(not g.can_see(p), "a guard on high ground does not see the floor below")
	var mid: int = g.cone_rays / 2
	var calm: float = g._cone_reach()[mid]
	g._set_state(g.State.SUSPICIOUS)
	_check(g.can_see(p), "unless he is already alerted")
	var alert: float = g._cone_reach()[mid]
	_check(calm < 6.0 and is_equal_approx(alert, g.cone_length),
		"and his drawn cone stops at the drop until then (%.1f m, then %.1f m)" % [calm, alert])
	g._set_state(g.State.PATROL)
	g.meter = 0.0


func _noise() -> void:
	var p: CharacterBody3D = _s.player
	var g: CharacterBody3D = _s.map.get_node("Guards/EastSentry")
	var plat: CharacterBody3D = _s.map.get_node("Guards/Platform")
	var north: CharacterBody3D = _s.map.get_node("Guards/NorthRoom")
	for guard in _s.map.guards:
		guard.reset_to_patrol()
	await _place(Vector3(-17, 0, 13))
	var center := Vector3(10, 0, 9)

	g._set_state(g.State.KNOCKED_OUT)
	var noise: Node3D = _s.emit_noise(center, 6.0)
	_check(noise.guards_inside(_s.map.guards).is_empty(), "a knocked-out guard is not counted by a noise")
	await _frames(60)
	_check(g.state == g.State.KNOCKED_OUT, "nor alerted by it")
	g._set_state(g.State.PATROL)
	await _frames(60)
	_check(not is_instance_valid(noise), "a noise clears itself away")

	noise = _s.emit_noise(center, 6.0)
	_check(noise.guards_inside(_s.map.guards) == [g], "a noise catches the guards inside its outline")
	await _frames(4)
	_check(g.state == g.State.PATROL, "the ring has not reached him yet")
	await _shot("8_noise")
	await _frames(40)
	_check(g.state == g.State.SUSPICIOUS and g._interest.is_equal_approx(center),
		"when it does he is alerted and heads for the centre")
	_check(plat.state == g.State.PATROL and north.state == g.State.PATROL,
		"guards outside the outline are unaffected")
	g.set_physics_process(true)
	var arrived := false
	for i in 300:
		await get_tree().physics_frame
		if g.global_position.distance_to(center) < 1.0:
			arrived = true
			break
	_check(arrived, "he walks to the centre")
	g.set_physics_process(false)

	await _place(Vector3(-15, 0, 12))
	_press(&"stealth_debug_noise")
	await _frames(2)
	var fired := get_tree().get_nodes_in_group(&"stealth_noise")
	_check(fired.size() == 1 and fired[0].global_position.distance_to(p.global_position) < 0.1,
		"the debug key fires a test noise at the player")
	await _frames(120)


func _alarm() -> void:
	var p: CharacterBody3D = _s.player
	var g: CharacterBody3D = _s.map.get_node("Guards/EastSentry")
	var plat: CharacterBody3D = _s.map.get_node("Guards/Platform")
	var north: CharacterBody3D = _s.map.get_node("Guards/NorthRoom")
	await _place(Vector3(-17, 0, 13))
	for guard in _s.map.guards:
		guard.reset_to_patrol()
	_guards_run(true)
	await _frames(40)
	_check(absf(wrapf(g.rotation.y - PI / 2, -PI, PI)) < 0.05,
		"a one-marker guard faces the way his marker points")
	p.teleport(Vector3(9.5, 0, 9))
	var saw_suspicious := false
	for i in 300:
		await get_tree().physics_frame
		saw_suspicious = saw_suspicious or g.state == g.State.SUSPICIOUS
		if _s.alarms > 0:
			break
	_check(saw_suspicious, "a filling meter makes him suspicious first")
	_check(_s.alarms == 1 and _s.alarm_active and _s.crisis_level == 1,
		"a full meter starts an alarm and raises the crisis level")
	_check(g.state == g.State.ALARMED and plat.state == g.State.ALARMED,
		"guards in the area are alarmed")
	_check(north.state == g.State.PATROL, "a guard far away is not")
	await _shot("6_alarm")
	for i in 300:
		await get_tree().physics_frame
		if _s.catches > 0:
			break
	await _frames(3)
	_check(_s.catches == 1, "an alarmed guard who reaches him catches him")
	_check(p.global_position.distance_to(Vector3(-14, 0, 10)) < 0.2,
		"he is back at the last checkpoint")
	_check(_s.crisis_level == 1 and not _s.alarm_active,
		"the crisis level is kept, the alarm is over")
	_check(g.state == g.State.PATROL and g.meter == 0.0, "the guards are back on patrol")

	# A second alarm, then out of sight: searching, then patrol.
	await _place(Vector3(-17, 0, 13))
	await _frames(40)
	p.teleport(Vector3(9.5, 0, 9))
	for i in 300:
		await get_tree().physics_frame
		if _s.alarms > 1:
			break
	_check(_s.alarms == 2 and _s.crisis_level == 2, "a second alarm raises the crisis level again")
	p.teleport(Vector3(-17, 0, 13))
	var searched := false
	for i in 400:
		await get_tree().physics_frame
		if g.state == g.State.SEARCHING:
			searched = true
			break
	_check(searched and not _s.alarm_active,
		"out of sight for a few seconds, the alarm drops to searching")
	_check(g.global_position.distance_to(Vector3(13, 0, 9)) > 1.0,
		"he had converged on where the player was last seen")
	var patrolling := false
	for i in 700:
		await get_tree().physics_frame
		if g.state == g.State.PATROL:
			patrolling = true
			break
	_check(patrolling, "and then back to patrol")
	_check(_s.catches == 1, "without another catch")

	var path := NavigationServer3D.map_get_path(get_viewport().world_3d.navigation_map,
		Vector3(-14, 0, 10), Vector3(16, 0, 12), true)
	_check(path.size() > 2 and path[-1].distance_to(Vector3(16, 0, 12)) < 1.0,
		"the baked navigation finds a way through the doors (%d points)" % path.size())
	var a := north.global_position
	var walked := 0.0
	var top := 0.0
	for i in 1500:
		await get_tree().physics_frame
		walked = maxf(walked, north.global_position.distance_to(a))
		top = maxf(top, plat.global_position.y)
		if top > 1.9 and walked > 3.0:
			break
	_check(walked > 3.0, "patrolling guards walk their paths")
	_check(top > 1.9, "and one patrol climbs the ramp onto the platform (y %.2f)" % top)
	_guards_run(false)


# --- helpers ---

func _guards_run(on: bool) -> void:
	for guard in _s.map.guards:
		guard.set_physics_process(on)


func _place(pos: Vector3) -> void:
	_s.player.teleport(pos)
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


## Holds the movement keys that head along a world direction, whatever the camera's yaw.
func _steer(world_dir: Vector3) -> void:
	var local := world_dir.rotated(Vector3.UP, -_s.get_node("CameraRig").yaw())
	for pair: Array in [[&"stealth_right", local.x], [&"stealth_left", -local.x],
			[&"stealth_down", local.z], [&"stealth_up", -local.z]]:
		if pair[1] > 0.01:
			Input.action_press(pair[0], minf(pair[1], 1.0))
		else:
			Input.action_release(pair[0])


func _walk_for(world_dir: Vector3, frames: int) -> void:
	_steer(world_dir.normalized())
	await _frames(frames)
	_steer(Vector3.ZERO)


func _walk_to(target: Vector3, max_frames: int) -> bool:
	var p: CharacterBody3D = _s.player
	for i in max_frames:
		var to := target - p.global_position
		to.y = 0.0
		if to.length() < 0.25:
			_steer(Vector3.ZERO)
			await _frames(4)
			return true
		_steer(to.normalized())
		await get_tree().physics_frame
	_steer(Vector3.ZERO)
	return false


func _shot(shot_name: String) -> void:
	if _shots.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join(shot_name + ".png"))


func _check(ok: bool, what: String) -> bool:
	if not ok:
		_failures += 1
	print("%s  %s" % ["ok  " if ok else "FAIL", what])
	return ok
