extends Node
## Shared game state, autoloaded as `Game`.
##
const VN_SCENE := "res://vn.tscn"
const FIRST_SHOT_SCENE := "res://first_shot/first_shot.tscn"
const FIRST_SHOT_CHAPTER := 3
const AFTERMATH_CHAPTER := 4
const STARTING_RIG_DEBT := 600
const FIRST_INSTALLMENT := 40
const CAPTURE_RECEIPT := {"followers": 120, "cash": 180}
const MISS_RECEIPT := {"followers": 15, "cash": 60}
const SAVE_VERSION := 2
const SLOTS_PER_DAY := 2
## The cold open. A version 1 save was only ever written after it.
const OPENER_SEGMENT := "d01_opener"

var _save_path := "user://campaign.save"
var has_checkpoint := false
var load_error := OK
var debug_first_shot := false

var stats := {
	"hype": 0,
	"sympathy": 0,
	"bloodlust": 0,
	"drama": 0,
	"patriotism": 0,
}
var followers := 0
var money := 0
var day := 1
## Calendar position. `slot` is 0 (day) or 1 (evening). `active_segment` is the
## segment in play, so a relaunch resumes it. `done_segments` counts completions.
var slot := 0
var active_segment := ""
var done_segments := {}
var flags := {}
var rig_debt := STARTING_RIG_DEBT
var first_shot_pending := false
var first_shot_outcome := ""
var first_shot_receipt := {}
var first_installment_paid := false

## The player character's name. Empty until the player enters it.
## Until then, Chip's nickname "Blockhead" is used.
var player_name := ""

## Lane geometry - the single source of truth for movement AND spawning.
var lane_count := 5
var lane_width := 4.0


func lane_x(index: int) -> float:
	return (index - (lane_count - 1) / 2.0) * lane_width


func display_name() -> String:
	var n := player_name.strip_edges()
	return n if n != "" else "Blockhead"


func set_player_name(raw: String) -> void:
	var n := raw.strip_edges()
	player_name = n if n != "" else "Commander"

## Story order. The VN walks these; add scenes here as you write them.
var chapters: Array[String] = [
	"res://scenes/00_prologue.txt",
	"res://scenes/01_intro.txt",
	"res://scenes/02_stream.txt",
	"res://scenes/03_car.txt",
	"res://scenes/04_mission_clear.txt",
]
var chapter_index := 0


func current_chapter() -> String:
	if chapter_index >= 0 and chapter_index < chapters.size():
		return chapters[chapter_index]
	return ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var fresh_debug := OS.is_debug_build() and "--debug-first-shot-fresh" in args
	debug_first_shot = fresh_debug or (OS.is_debug_build() and "--debug-first-shot" in args)
	if debug_first_shot:
		_save_path = "user://debug-first-shot.save"
	if not fresh_debug:
		load_error = load_campaign()
	if load_error == OK and debug_first_shot and not has_checkpoint:
		chapter_index = FIRST_SHOT_CHAPTER


func advance_chapter() -> Error:
	if chapter_index >= chapters.size():
		return OK
	if chapter_index == FIRST_SHOT_CHAPTER and first_shot_outcome.is_empty():
		return ERR_UNAVAILABLE
	var state := _snapshot()
	state.chapter_index = chapter_index + 1
	return _commit(state)


func start_first_shot() -> Error:
	if chapter_index != FIRST_SHOT_CHAPTER or not first_shot_outcome.is_empty():
		return ERR_UNAVAILABLE
	if first_shot_pending:
		return OK
	var state := _snapshot()
	state.first_shot_pending = true
	return _commit(state)


func record_first_shot(captured: bool) -> Error:
	if not first_shot_outcome.is_empty():
		return OK
	if chapter_index != FIRST_SHOT_CHAPTER:
		return ERR_UNAVAILABLE
	var state := _snapshot()
	var receipt := CAPTURE_RECEIPT if captured else MISS_RECEIPT
	state.first_shot_pending = false
	state.first_shot_outcome = "capture" if captured else "miss"
	state.first_shot_receipt = receipt.duplicate()
	state.followers = followers + int(receipt.followers)
	state.money = money + int(receipt.cash)
	state.chapter_index = AFTERMATH_CHAPTER
	return _commit(state)


func repay_first_installment() -> Error:
	if first_installment_paid:
		return ERR_ALREADY_EXISTS
	if first_shot_outcome.is_empty() or money < FIRST_INSTALLMENT or rig_debt < FIRST_INSTALLMENT:
		return ERR_UNAVAILABLE
	var state := _snapshot()
	state.money = money - FIRST_INSTALLMENT
	state.rig_debt = rig_debt - FIRST_INSTALLMENT
	state.first_installment_paid = true
	return _commit(state)


func begin_segment(id: String) -> Error:
	if active_segment == id:
		return OK
	var state := _snapshot()
	state.active_segment = id
	return _commit(state)


## Applies a segment's outputs and moves the calendar on, in one write.
## `outputs`: {"flags": {name: bool}, "stats": {name: delta}, "followers": n, "money": n}.
func complete_segment(id: String, outputs: Dictionary, slots_used: int) -> Error:
	var state := _snapshot()
	state.active_segment = ""
	state.done_segments[id] = int(state.done_segments.get(id, 0)) + 1
	for key in outputs.get("flags", {}):
		state.flags[key] = bool(outputs.flags[key])
	for key in outputs.get("stats", {}):
		state.stats[key] = int(state.stats.get(key, 0)) + int(outputs.stats[key])
	state.followers = followers + int(outputs.get("followers", 0))
	state.money = money + int(outputs.get("money", 0))
	state.slot = slot + slots_used
	if state.slot >= SLOTS_PER_DAY:
		state.day = day + 1
		state.slot = 0
	return _commit(state)


func jump_to_day(target: int) -> Error:
	var state := _snapshot()
	state.day = maxi(1, target)
	state.slot = 0
	state.active_segment = ""
	return _commit(state)


func segment_done(id: String) -> bool:
	return int(done_segments.get(id, 0)) > 0


func save_campaign() -> Error:
	return _commit(_snapshot())


func load_campaign() -> Error:
	if not FileAccess.file_exists(_save_path):
		return OK
	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var state: Variant = file.get_var()
	if not state is Dictionary:
		return ERR_FILE_CORRUPT
	if state.get("version") == 1:
		state.version = SAVE_VERSION
		state.slot = 0
		state.active_segment = ""
		state.done_segments = {OPENER_SEGMENT: 1}
	if state.get("version") != SAVE_VERSION:
		return ERR_FILE_CORRUPT
	var expected := _snapshot()
	for key in expected:
		if not state.has(key) or typeof(state[key]) != typeof(expected[key]):
			return ERR_FILE_CORRUPT
	_restore(state)
	has_checkpoint = true
	return OK


func _snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"chapter_index": chapter_index,
		"day": day,
		"slot": slot,
		"active_segment": active_segment,
		"done_segments": done_segments.duplicate(),
		"player_name": player_name,
		"stats": stats.duplicate(),
		"flags": flags.duplicate(),
		"followers": followers,
		"money": money,
		"rig_debt": rig_debt,
		"first_shot_pending": first_shot_pending,
		"first_shot_outcome": first_shot_outcome,
		"first_shot_receipt": first_shot_receipt.duplicate(),
		"first_installment_paid": first_installment_paid,
	}


func _restore(state: Dictionary) -> void:
	chapter_index = state.chapter_index
	day = state.day
	slot = state.slot
	active_segment = state.active_segment
	done_segments = state.done_segments
	player_name = state.player_name
	stats = state.stats
	flags = state.flags
	followers = state.followers
	money = state.money
	rig_debt = state.rig_debt
	first_shot_pending = state.first_shot_pending
	first_shot_outcome = state.first_shot_outcome
	first_shot_receipt = state.first_shot_receipt
	first_installment_paid = state.first_installment_paid


func _commit(state: Dictionary) -> Error:
	if load_error != OK:
		return load_error
	# Write the checkpoint, balances and receipt together before publishing them.
	var temporary := _save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var written := file.store_var(state)
	file.flush()
	var error := file.get_error()
	file.close()
	if not written or error != OK:
		return ERR_FILE_CANT_WRITE
	error = DirAccess.rename_absolute(temporary, _save_path)
	if error != OK:
		return error
	_restore(state)
	has_checkpoint = true
	return OK


func add_stat(key: String, amount: int) -> void:
	stats[key] = int(stats.get(key, 0)) + amount


func get_stat(key: String) -> int:
	return int(stats.get(key, 0))


func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func debug_line() -> String:
	return "day %d slot %d | followers %d | money %d | stats %s | flags %s" % [
		day, slot, followers, money, str(stats), str(flags)
	]
