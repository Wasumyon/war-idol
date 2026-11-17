extends Node
## Plays the intro from the start and checks each beat, then the hand-off to Chamber 0.
## SHOTS=<dir> saves a screenshot per beat.

var _fails: int = 0
var _shots: String = OS.get_environment("SHOTS")


func check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1


func _ready() -> void:
	_run.call_deferred()


func _shot(name: String) -> void:
	if _shots == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join(name + ".png"))


func _wait_beat(intro: Node, b: String, limit: float) -> bool:
	var t: float = 0.0
	while is_instance_valid(intro) and intro.beat != b and t < limit:
		await get_tree().process_frame
		t += get_process_delta_time()
	return is_instance_valid(intro) and intro.beat == b


func _run() -> void:
	# Leave the tree's current scene to a stand-in, so changing scenes doesn't free the test.
	var stand_in := Node.new()
	get_tree().root.add_child(stand_in)
	get_tree().current_scene = stand_in
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://minigames/tunnel/scenes/intro.tscn", "game starts on the intro")
	get_tree().change_scene_to_file("res://minigames/tunnel/scenes/intro.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var intro: Node = get_tree().current_scene
	check(intro != null and intro.scene_file_path.ends_with("intro.tscn"), "intro loads")
	var t0: int = Time.get_ticks_msec()
	for b: String in ["line1", "line2", "line3", "gap", "cg", "jump"]:
		var ok: bool = await _wait_beat(intro, b, 6.0)
		check(ok, "beat " + b)
		if b != "gap":
			await get_tree().create_timer(0.5 if b != "cg" else 1.6).timeout
			await _shot("intro_" + b)
	var waited: float = 0.0
	while waited < 6.0 and not get_tree().current_scene.scene_file_path.ends_with("chamber_0.tscn"):
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	var total: float = (Time.get_ticks_msec() - t0) / 1000.0
	check(get_tree().current_scene.scene_file_path.ends_with("chamber_0.tscn"), "hands off to Chamber 0 (%.1f s)" % total)
	await get_tree().create_timer(1.2).timeout
	await _shot("intro_z_chamber0")
	var player: Node = get_tree().current_scene.find_child("Player", true, false)
	check(player != null, "Chamber 0 has the player falling")

	# Skip: Enter during the intro goes straight to Chamber 0.
	get_tree().change_scene_to_file("res://minigames/tunnel/scenes/intro.tscn")
	await get_tree().create_timer(1.5).timeout
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(1.5).timeout
	check(get_tree().current_scene.scene_file_path.ends_with("chamber_0.tscn"), "Enter skips to Chamber 0")
	print("RESULT %d failures" % _fails)
	get_tree().quit(_fails)
