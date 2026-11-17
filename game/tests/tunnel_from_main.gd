extends Node
## Main launches Tunnel Escape through the debug panel's function, the segment finishes,
## and Main is back at the hub with the day, slot and save untouched.

const MAIN := preload("res://main/main.tscn")

var _fails := 0


func _ready() -> void:
	_run.call_deferred()


func _check(c: bool, name: String) -> void:
	if not c:
		_fails += 1
	print(("PASS " if c else "FAIL ") + name)


func _run() -> void:
	get_tree().create_timer(60.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timed out")
		get_tree().quit(2))
	var save_path := OS.get_temp_dir().path_join("war-idol-tunnel-main-%d.save" % OS.get_process_id())
	GameState._save_path = save_path
	GameState.load_error = OK
	GameState.has_checkpoint = false
	GameState.debug_first_shot = false
	GameState.jump_to_day(2)
	var main: Node = MAIN.instantiate()
	get_tree().root.add_child(main)
	var hub: Node = await main.shown
	_check(hub.name == &"Hub", "Main opens on the hub")
	var day := GameState.day
	var slot := GameState.slot
	var money := GameState.money

	main.debug_tunnel()
	var seg: Node = await main.shown
	_check(seg.name == &"TunnelSegment" or seg.has_signal("finished"), "debug_tunnel shows the tunnel segment")
	_check(main.current == seg and main.current_id == "debug:tunnel", "Main is in the tunnel")
	main.debug_skip()   # must not treat the debug segment as a calendar one
	await get_tree().process_frame
	_check(main.current == seg, "Skip segment leaves the debug tunnel alone")

	seg._on_escaped()
	var back: Node = await main.shown
	_check(back.name == &"Hub" and main.current_id == "", "finishing returns to the hub")
	_check(GameState.day == day and GameState.slot == slot and GameState.money == money,
		"day, slot and money are untouched")
	await get_tree().process_frame
	_check(not is_instance_valid(seg) or seg.is_queued_for_deletion(), "the segment is freed")

	DirAccess.remove_absolute(save_path)
	print("%d failure(s)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
