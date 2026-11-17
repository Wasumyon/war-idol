extends Node
## Run with --headless --path game res://tests/first_shot_campaign.tscn.
##
## Drives Main the way a player would: the Day 1 opening and its payout, then the
## calendar loop (free slot, scripted VN day, scripted minigame day, resume, end).

const MAIN := preload("res://main/main.tscn")

var _failures := 0
var _save_path := ""
var _fresh: Dictionary
var _main: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var defaults: Node = GameState.get_script().new()
	_fresh = defaults._snapshot()
	defaults.free()
	_save_path = OS.get_temp_dir().path_join("war-idol-campaign-test-%d.save" % OS.get_process_id())
	GameState._save_path = _save_path
	GameState.load_error = OK
	GameState.has_checkpoint = false
	GameState.debug_first_shot = false
	GameState._restore(_fresh.duplicate(true))

	_check_migration()
	GameState._restore(_fresh.duplicate(true))
	DirAccess.remove_absolute(_save_path)

	var opener: Node = await _boot()
	if not _check(opener.name == &"Opener", "a fresh launch opens on the cold open"):
		return _finish()
	_click(opener._target)
	_check(opener._phase == opener.Phase.INCOMING, "normal launch accepts opener shot")
	opener._process(3.0)
	opener._process(1.0)
	opener._process(2.0)
	var story: Node = await _main.shown
	_check(story.name == &"Vn" and GameState.segment_done("d01_opener"), "the opener hands off to the story")
	var shot: Node = await _play_vn(story)
	_check(shot != null and shot.name == &"FirstShot", "campaign hands off to Chip's filming request")
	_reload()
	_check(GameState.first_shot_pending and GameState.active_segment == "d01_opening", "reload the unspent shot checkpoint")
	await _boot()
	await _check_outcome("capture", 120, 180)
	await _check_calendar()
	await _check_outcome("miss", 15, 60)
	await _check_outcome("timeout", 15, 60)
	_finish()


func _finish() -> void:
	DirAccess.remove_absolute(_save_path)
	print("First shot campaign test: %d failure(s)" % _failures)
	get_tree().quit(int(_failures > 0))


func _check_migration() -> void:
	var old := _fresh.duplicate(true)
	old.version = 1
	old.chapter_index = 2
	for key in ["slot", "active_segment", "done_segments"]:
		old.erase(key)
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	file.store_var(old)
	file.close()
	_check(GameState.load_campaign() == OK, "a version 1 save loads")
	_check(GameState.chapter_index == 2 and GameState.segment_done("d01_opener") and GameState.slot == 0,
		"a version 1 save resumes after the opener")


func _check_outcome(mode: String, expected_followers: int, expected_cash: int) -> void:
	if mode != "capture":
		GameState._restore(_fresh.duplicate(true))
		GameState.chapter_index = GameState.FIRST_SHOT_CHAPTER
		GameState.done_segments = {"d01_opener": 1}
		GameState.active_segment = "d01_opening"
		GameState.first_shot_pending = true
		_check(GameState.save_campaign() == OK, "write fresh filming checkpoint")
		await _boot()
	var shot: Node = _main.current
	if not _check(shot.name == &"FirstShot", "filming scene entered"):
		return
	var outcome := "capture" if mode == "capture" else "miss"
	if mode == "timeout":
		shot._process(shot.WINDOW)
	else:
		_click(shot._subject if mode == "capture" else Vector2(100, 100))
		_click(Vector2(100, 100) if mode == "capture" else shot._subject)
	await _main.shown
	_check(_main.current.name == &"Vn", mode + " returns to the story")
	_check(GameState.first_shot_outcome == outcome, mode + " records the correct outcome")
	_check(GameState.chapter_index == GameState.AFTERMATH_CHAPTER and GameState.day == 1, mode + " saves the aftermath on Day 1")
	_check(GameState.followers == expected_followers and GameState.money == expected_cash, mode + " awards exactly one payout")
	_check(GameState.rig_debt == GameState.STARTING_RIG_DEBT, mode + " preserves initial debt")
	if mode == "capture":
		_check(GameState.player_name == "Test Pilot", "player name survives the handoff")

	_reload()
	_check(GameState.record_first_shot(mode != "capture") == OK, mode + " handles a duplicate submission")
	_check(GameState.first_shot_outcome == outcome and GameState.money == expected_cash and GameState.followers == expected_followers,
		mode + " duplicate submission preserves original outcome and payout")
	var story: Node = await _boot()
	var expected_line := "Right in the frame!" if outcome == "capture" else "Aaaand there it goes."
	_check(story.name == &"Vn" and story.text_label.text.contains(expected_line),
		mode + " plays the matching Chip callback on reload")
	story._advance()
	story._advance()
	var phone: ColorRect = story._phone
	_check(phone.visible, mode + " opens the phone after Chip's callback")
	var pay: Button
	for child in phone._content.get_children():
		if child is Button:
			pay = child
	if _check(pay != null and not pay.disabled, mode + " offers an affordable repayment"):
		pay.pressed.emit()
	_check(GameState.repay_first_installment() == ERR_ALREADY_EXISTS, mode + " rejects another repayment")
	_check(GameState.money == expected_cash - 40 and GameState.rig_debt == 560, mode + " debits cash and debt once")
	_reload()
	story = await _boot()
	story.phone_button.pressed.emit()
	phone = story._phone
	var paid_label := false
	for child in phone._content.get_children():
		if child is Label and child.text.begins_with("First installment paid"):
			paid_label = true
		_check(not child is Button, mode + " removes the repay button on revisit")
	_check(paid_label and GameState.first_installment_paid, mode + " shows the saved payment on revisit")
	_check(GameState.money == expected_cash - 40 and GameState.rig_debt == 560 and GameState.followers == expected_followers,
		mode + " preserves all balances after reloading and revisiting")
	await get_tree().process_frame
	var shell: PanelContainer = phone.get_child(0).get_child(0)
	_check(phone.get_viewport_rect().encloses(shell.get_global_rect()), "fold-out phone fits the game viewport")
	if mode == "capture":
		phone._shortcuts["Feed"].pressed.emit()
		_check(phone._content.get_child(1).text == "120 followers", "Feed shows the saved follower total")
		phone._shortcuts["Shop"].pressed.emit()
		_check(phone._content.get_child(1).text == "Shop closed", "Shop shortcut opens its page")
		phone._close.pressed.emit()
		story._advance()
		story._advance()
		phone._close.pressed.emit()
		for step in 12:
			if story.choices.get_child_count() > 0:
				break
			story._advance()
		if not _check(story.choices.get_child_count() == 3, "closing the phone reaches the canteen choices"):
			return
		var choice: Button = story.choices.get_child(0)
		choice.pressed.emit()
		var hub: Node = await _play_vn(story)
		_check(hub != null and hub.name == &"Hub", "the opening ends in the hub")
		_check(GameState.day == 2 and GameState.slot == 0, "finishing the opening advances to Day 2")
		_reload()
		_check(GameState.day == 2 and GameState.current_chapter().is_empty() and GameState.active_segment == "",
			"opening completion survives reload")


## Runs straight after the capture path: Day 2, day slot, $140, 120 followers.
func _check_calendar() -> void:
	var hub: Node = await _boot()
	if not _check(hub.name == &"Hub", "a relaunch on Day 2 opens the hub"):
		return
	_check(hub.get_node("Header").text.begins_with("DAY 02") and _main._phone_button.visible,
		"the hub shows the day and the phone")
	hub.get_node("Calendar").pressed.emit()
	_check(hub.get_node("Panel/Column/Body/Grid").get_child_count() == 40, "the calendar shows 40 days")
	var offers := _offers(hub)
	_check("offer_rest" in offers and "offer_canteen" in offers and "offer_runner_easy" in offers,
		"a free slot lists the open offers")
	_check(not "offer_runner_hard" in offers, "a flag-gated offer stays hidden")

	hub = await _choose(hub, "offer_rest")
	_check(hub.name == &"Hub" and GameState.day == 2 and GameState.slot == 1, "resting passes one slot")
	_check(_offers(hub) == ["d02_keno_evening"], "a scripted slot offers only its story segment")
	var story: Node = await _choose(hub, "d02_keno_evening")
	_check(story.name == &"Vn", "a VN day plays in the story layer")
	hub = await _play_vn(story)
	_check(hub != null and hub.name == &"Hub" and GameState.day == 3 and GameState.slot == 0,
		"the VN day ends and the day advances")
	_check(GameState.has_flag("met_keno_evening"), "a segment's flag output is applied")

	_check(_offers(hub) == ["d03_frontline"], "Day 3 scripts the frontline")
	var runner: Node = await _choose(hub, "d03_frontline")
	_check(runner.name == &"RunnerSegment", "a minigame day plays in the world layer")
	runner._run._end_run()
	runner.continue_run()
	hub = await _main.shown
	_check(GameState.followers == 320 and GameState.money == 290, "the minigame outcome pays once")
	_check(GameState.has_flag("perimeter_filmed") and GameState.day == 3 and GameState.slot == 1, "the minigame day uses one slot")
	_check("offer_runner_hard" in _offers(hub), "the flag opens the gated offer")
	_reload()
	_check(GameState.followers == 320 and GameState.money == 290 and GameState.slot == 1, "the payout survives reload")

	hub = await _boot()
	story = await _choose(hub, "offer_canteen")
	_reload()
	_check(GameState.active_segment == "offer_canteen", "the segment in play is saved")
	story = await _boot()
	_check(story.name == &"Vn" and _main.current_id == "offer_canteen", "a relaunch resumes the segment")
	hub = await _play_vn(story)
	_check(hub != null and GameState.day == 4 and GameState.slot == 0, "the evening slot ends the day")
	_check(not "offer_canteen" in _offers(hub), "a once-only offer does not return")

	_main.debug_jump(41)
	var card: Node = await _main.shown
	_check(card.name == &"EndCard", "the calendar ends after the last day")


func _offers(hub: Node) -> Array:
	hub.get_node("Missions").pressed.emit()
	var ids := []
	for child in hub.get_node("Panel/Column/Body").get_children():
		if not child.is_queued_for_deletion():
			ids.append(str(child.name))
	return ids


func _choose(hub: Node, id: String) -> Node:
	_offers(hub)
	hub.get_node("Panel/Column/Body/" + id).pressed.emit()
	return await _main.shown


## Clicks through a VN until Main swaps it out; returns what replaced it.
func _play_vn(story: Node) -> Node:
	for step in 2000:
		if story.name_panel.visible:
			story.name_input.text = "Test Pilot"
			story._confirm_name()
		story._advance()
		if _main.transition.is_busy():
			return await _main.shown
	_check(false, "the story never handed off")
	return null


## A relaunch: a new Main over whatever GameState holds now.
func _boot() -> Node:
	# Never free Main from inside its own signal: let the emit return first.
	await get_tree().process_frame
	if is_instance_valid(_main):
		_main.free()
	_main = MAIN.instantiate()
	get_tree().root.add_child(_main)
	return await _main.shown


func _reload() -> void:
	GameState._restore(_fresh.duplicate(true))
	_check(GameState.load_campaign() == OK, "the save reloads")


func _click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	event.global_position = point
	get_tree().root.push_input(event, true)


func _check(condition: bool, message: String) -> bool:
	if not condition:
		_failures += 1
		push_error(message)
	return condition
