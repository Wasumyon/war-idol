extends Node
## Run with --headless --fixed-fps 60 --path vn res://tests/stealth_smoke.tscn.
## Plays the stealth test map through its rules with synthetic input. Must print 0 failures.
## Set STEALTH_SHOTS to a folder and run without --headless to also save screenshots.

const STEALTH := preload("res://stealth/stealth.tscn")

var _failures := 0
var _s: Node
var _result := {}
var _shots := OS.get_environment("STEALTH_SHOTS")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_s = STEALTH.instantiate()
	_s.begin({"map": "test_map"})
	_s.finished.connect(func(result: Dictionary) -> void: _result = result)
	add_child(_s)
	await _frames(20)
	await _movement()
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
	_check(_result.has("outcome"), "reaching the exit emits finished with an outcome: %s" % [_result])
	await _shot("9_exit")


# --- helpers ---

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
