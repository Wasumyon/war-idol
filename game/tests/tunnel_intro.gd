extends "res://tests/tunnel_test.gd"
## Plays the intro from the start and checks each beat, then the hand-off to Chamber 0.
## Runs through tunnel_segment.tscn begun with start "intro" (see tunnel_test.gd).
## SHOTS=<dir> saves a screenshot per beat.

const INTRO := "res://minigames/tunnel/scenes/intro.tscn"


func check(cond: bool, what: String) -> void:
	ok(cond, what)


func _ready() -> void:
	_run.call_deferred()


func _wait_beat(intro: Node, b: String, limit: float) -> bool:
	var t: float = 0.0
	while is_instance_valid(intro) and intro.beat != b and t < limit:
		await get_tree().process_frame
		t += get_process_delta_time()
	return is_instance_valid(intro) and intro.beat == b


func _chamber_is(name: String) -> bool:
	return is_instance_valid(m.chamber) and m.chamber.scene_file_path.ends_with(name)


func _run() -> void:
	await start_segment({"start": "intro"})
	# NOT PORTED: check(ProjectSettings main_scene == intro.tscn, "game starts on the intro").
	# The game's main scene is Main now; the segment's own start is the check below.
	var intro: Node = m.chamber
	check(intro != null and intro.scene_file_path.ends_with("intro.tscn"), "intro loads (segment start 'intro')")
	var t0: int = Time.get_ticks_msec()
	for b: String in ["line1", "line2", "line3", "gap", "cg", "jump"]:
		var reached: bool = await _wait_beat(intro, b, 6.0)
		check(reached, "beat " + b)
		if b != "gap":
			await get_tree().create_timer(0.5 if b != "cg" else 1.6).timeout
			await shot("intro_" + b)
	var waited: float = 0.0
	while waited < 6.0 and not _chamber_is("chamber_0.tscn"):
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	var total: float = (Time.get_ticks_msec() - t0) / 1000.0
	check(_chamber_is("chamber_0.tscn"), "hands off to Chamber 0 (%.1f s)" % total)
	await get_tree().create_timer(1.2).timeout
	await shot("intro_z_chamber0")
	await settle()
	check(p != null, "Chamber 0 has the player falling")

	# Skip: Enter during the intro goes straight to Chamber 0.
	await load_chamber(INTRO)
	await get_tree().create_timer(1.5).timeout
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(1.5).timeout
	check(_chamber_is("chamber_0.tscn"), "Enter skips to Chamber 0")
	finish()
