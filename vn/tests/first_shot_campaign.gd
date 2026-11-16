extends Node
## Run with --headless --path vn res://tests/first_shot_campaign.tscn.

var _failures := 0
var _save_path := ""
var _fresh: Dictionary


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().current_scene = null
	var defaults: Node = Game.get_script().new()
	_fresh = defaults._snapshot()
	defaults.free()
	_save_path = OS.get_temp_dir().path_join("war-idol-campaign-test-%d.save" % OS.get_process_id())
	Game._save_path = _save_path
	Game.load_error = OK
	Game.has_checkpoint = false
	Game.debug_first_shot = false
	Game._restore(_fresh.duplicate(true))

	await _open("res://opener/opener.tscn")
	var opener := get_tree().current_scene
	_click(opener._target)
	_check(opener._phase == opener.Phase.INCOMING, "normal launch accepts opener shot")
	opener._process(3.0)
	opener._process(1.0)
	opener._process(2.0)
	await get_tree().scene_changed
	await _advance_to_first_shot()
	Game._restore(_fresh.duplicate(true))
	_check(Game.load_campaign() == OK and Game.first_shot_pending, "reload the unspent shot checkpoint")
	await _open("res://opener/opener.tscn")
	if get_tree().current_scene.name == &"Opener":
		await get_tree().scene_changed
	await _check_outcome("capture", 120, 180)
	await _check_outcome("miss", 15, 60)
	await _check_outcome("timeout", 15, 60)

	DirAccess.remove_absolute(_save_path)
	print("First shot campaign test: %d failure(s)" % _failures)
	get_tree().quit(int(_failures > 0))


func _advance_to_first_shot() -> void:
	for step in 2000:
		var story := get_tree().current_scene
		if story.name == &"FirstShot":
			return
		if story.name != &"Vn":
			break
		if story.name_panel.visible:
			story.name_input.text = "Test Pilot"
			story._confirm_name()
		story._advance()
		if get_tree().current_scene == null:
			await get_tree().scene_changed
	_check(false, "campaign hands off to Chip's filming request")


func _check_outcome(mode: String, expected_followers: int, expected_cash: int) -> void:
	if mode != "capture":
		Game._restore(_fresh.duplicate(true))
		Game.chapter_index = Game.FIRST_SHOT_CHAPTER
		_check(Game.save_campaign() == OK, "write fresh filming checkpoint")
		await _open(Game.FIRST_SHOT_SCENE)
	var shot := get_tree().current_scene
	if not _check(shot.name == &"FirstShot", "filming scene entered"):
		return
	var outcome := "capture" if mode == "capture" else "miss"
	if mode == "timeout":
		shot._process(shot.WINDOW)
	else:
		_click(shot._subject if mode == "capture" else Vector2(100, 100))
		_click(Vector2(100, 100) if mode == "capture" else shot._subject)
	await get_tree().scene_changed
	_check(Game.first_shot_outcome == outcome, mode + " records the correct outcome")
	_check(Game.chapter_index == Game.AFTERMATH_CHAPTER and Game.day == 1, mode + " saves the aftermath on Day 1")
	_check(Game.followers == expected_followers and Game.money == expected_cash, mode + " awards exactly one payout")
	_check(Game.rig_debt == Game.STARTING_RIG_DEBT, mode + " preserves initial debt")
	if mode == "capture":
		_check(Game.player_name == "Test Pilot", "player name survives the handoff")

	Game._restore(_fresh.duplicate(true))
	_check(Game.load_campaign() == OK, mode + " reloads the payout")
	_check(Game.record_first_shot(mode != "capture") == OK, mode + " handles a duplicate submission")
	_check(Game.first_shot_outcome == outcome and Game.money == expected_cash and Game.followers == expected_followers,
		mode + " duplicate submission preserves original outcome and payout")
	await _open("res://opener/opener.tscn")
	if get_tree().current_scene.name == &"Opener":
		await get_tree().scene_changed
	var story := get_tree().current_scene
	var expected_line := "Right in the frame!" if outcome == "capture" else "Aaaand there it goes."
	_check(story.text_label.text.contains(expected_line), mode + " plays the matching Chip callback on reload")
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
	_check(Game.repay_first_installment() == ERR_ALREADY_EXISTS, mode + " rejects another repayment")
	_check(Game.money == expected_cash - 40 and Game.rig_debt == 560, mode + " debits cash and debt once")
	Game._restore(_fresh.duplicate(true))
	_check(Game.load_campaign() == OK, mode + " reloads the repayment")
	await _open(Game.VN_SCENE)
	story = get_tree().current_scene
	story.phone_button.pressed.emit()
	phone = story._phone
	var paid_label := false
	for child in phone._content.get_children():
		if child is Label and child.text.begins_with("First installment paid"):
			paid_label = true
		_check(not child is Button, mode + " removes the repay button on revisit")
	_check(paid_label and Game.first_installment_paid, mode + " shows the saved payment on revisit")
	_check(Game.money == expected_cash - 40 and Game.rig_debt == 560 and Game.followers == expected_followers,
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
		story._advance()
		story._advance()
		Game._restore(_fresh.duplicate(true))
		_check(Game.load_campaign() == OK and Game.current_chapter().is_empty(), "aftermath completion survives reload")
		await _open(Game.VN_SCENE)
		story = get_tree().current_scene
		_check(story._ended and story.phone_button.visible, "completed campaign can still reopen the phone")


func _open(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if _check(error == OK, "open " + path):
		await get_tree().scene_changed


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
