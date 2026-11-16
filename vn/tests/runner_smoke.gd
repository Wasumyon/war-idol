extends Node
## Headless smoke test: godot --headless --path vn res://tests/runner_smoke.tscn

var _failures := 0
var _results: Array[Dictionary] = []


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		_failures += 1


func _ready() -> void:
	var seg: Node = load("res://runner/runner_segment.tscn").instantiate()
	seg.begin({"route": "easy", "zone": "supply_road"})
	seg.finished.connect(func(r: Dictionary) -> void: _results.append(r))
	add_child(seg)
	await get_tree().process_frame
	await get_tree().physics_frame
	var first: Node = seg._slice
	_check(first != null and first.is_inside_tree(), "begin + enter tree starts a run")

	seg.continue_run()
	_check(_results.is_empty(), "continue is ignored while the run is live")

	first._end_run()
	_check(not first.run_active, "the run can be forced to end")
	seg.continue_run()
	_check(_results.size() == 1, "finished fires once on continue")
	var r: Dictionary = _results[0] if not _results.is_empty() else {}
	_check(r.has("outcome") and r.has("followers") and r.has("money") and r.size() == 3,
		"result has exactly outcome, followers, money")
	_check(r.get("outcome") == "good", "shields left means a good outcome")
	seg.continue_run()
	_check(_results.size() == 1, "finished never fires twice")

	# Bad outcome and restart, on a second segment.
	var seg2: Node = load("res://runner/runner_segment.tscn").instantiate()
	seg2.begin({})
	var results2: Array[Dictionary] = []
	seg2.finished.connect(func(x: Dictionary) -> void: results2.append(x))
	add_child(seg2)
	await get_tree().process_frame
	var old: Node = seg2._slice
	old.followers = 42.0
	old.shields = 0
	old._end_run()
	var key := InputEventKey.new()
	key.keycode = KEY_R
	key.pressed = true
	seg2._unhandled_input(key)
	await get_tree().process_frame
	var fresh: Node = seg2._slice
	_check(fresh != old and fresh.run_active and fresh.shields == 3 and fresh.followers == 0.0,
		"R gives a fresh run")
	_check(not is_instance_valid(old) or old.is_queued_for_deletion() or not old.is_inside_tree(),
		"R frees the old run")
	_check(results2.is_empty(), "R does not finish the segment")
	fresh.shields = 0
	fresh.followers = 77.0
	fresh._end_run()
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	seg2._unhandled_input(enter)
	_check(results2.size() == 1 and results2[0].get("outcome") == "bad" and results2[0].get("followers") == 77,
		"Enter ends with a bad outcome and the run's followers")

	print("runner smoke: %d failures" % _failures)
	get_tree().quit(1 if _failures else 0)
