extends Node
## The game's one persistent scene. Spec: docs/maingame_spec.md.
##
## It asks the calendar what plays next, swaps that in through the Transition layer,
## waits for the segment's finished(result), saves, and asks again. Segments never
## change scene and never advance the day themselves.
##
## A segment is any scene whose root has:  signal finished(result: Dictionary)
## and optionally:                         func begin(args: Dictionary)  (called before it enters the tree)

signal shown(node: Node)   ## a swap has completed; the tests wait on this
signal _clicked

const CALENDAR := preload("res://calendar/calendar.gd")
const VN_SCENE := preload("res://vn.tscn")
const FIRST_SHOT_SCENE := preload("res://first_shot/first_shot.tscn")
const HUB_SCENE := preload("res://hub/hub.tscn")
const PHONE := preload("res://phone/campaign_phone.gd")
const DOSSIER_DATA := preload("res://dossier/dossier_data.gd")
const OPENING_SEGMENT := "d01_opening"

@onready var world: Node = $World
@onready var story: CanvasLayer = $Story
@onready var hud: CanvasLayer = $HUD
@onready var pause: CanvasLayer = $Pause
@onready var dossier: CanvasLayer = $Dossier   ## the files: an overlay, not a segment
@onready var transition: CanvasLayer = $Transition

var current: Node          ## the hub or the segment on screen
var current_id := ""       ## the segment in play; "" in the hub

var _notice: Label
var _phone: Control
var _phone_button: Button


func _ready() -> void:
	_notice = Label.new()
	_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_notice.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_notice.offset_bottom = -24
	_notice.hide()
	transition.add_child(_notice)
	_phone_button = Button.new()
	_phone_button.name = "PhoneButton"
	_phone_button.text = "Phone"
	_phone_button.position = Vector2(868, 12)
	_phone_button.hide()
	_phone_button.pressed.connect(func() -> void: _phone.open())
	hud.add_child(_phone_button)
	dossier.closed.connect(_dossier_closed)
	if OS.is_debug_build():
		for problem in CALENDAR.validate():
			push_error("Calendar: " + problem)
		for problem in DOSSIER_DATA.validate():
			push_error("Dossier: " + problem)
		for warning in DOSSIER_DATA.warnings():
			push_warning("Dossier: " + warning)
	_next.call_deferred()


func _input(event: InputEvent) -> void:
	if _notice.visible and event is InputEventMouseButton and event.pressed:
		_clicked.emit()


# ---------------------------------------------------------------------------
# The loop: calendar -> segment -> calendar
# ---------------------------------------------------------------------------
func _next() -> void:
	if Game.load_error != OK:
		_say("The campaign save could not be loaded.")
		return
	var step := CALENDAR.next_step()
	match step.kind:
		"segment":
			await _start(step.id)
		"hub":
			await _open_hub()
		"end":
			await _show(_end_card(), world)


func _open_hub() -> void:
	current_id = ""
	var hub := HUB_SCENE.instantiate()
	hub.setup(CALENDAR.offers())
	hub.segment_chosen.connect(_start, CONNECT_ONE_SHOT)
	hub.menu_requested.connect(pause.open)
	hub.dossiers_requested.connect(dossier.open)
	await _show(hub, world)


## The hub's Dossiers label shows the unread count, which the files just changed.
func _dossier_closed() -> void:
	if is_instance_valid(current) and current.has_method("refresh_dossier_count"):
		current.refresh_dossier_count()


func _start(id: String) -> void:
	if Game.debug_first_shot and id == Game.OPENER_SEGMENT:
		await _complete(id, {})
		return
	await _save(func() -> Error: return Game.begin_segment(id))
	current_id = id
	var seg := CALENDAR.segment(id)
	match str(seg.get("type", "")):
		"skip":
			await _complete(id, {})
		"vn":
			if id == OPENING_SEGMENT and _first_shot_due():
				await _show_first_shot()
			else:
				await _show_vn(str(seg.get("source", "")))
		"minigame":
			var node: Node = load(seg.source).instantiate()
			if node.has_method("begin"):
				node.begin(seg.get("args", {}))
			node.finished.connect(func(result: Dictionary) -> void: _complete(id, result), CONNECT_ONE_SHOT)
			await _show(node, world)


func _complete(id: String, result: Dictionary) -> void:
	var outputs := CALENDAR.outputs_for(id, result)
	var used := CALENDAR.slots_used(id)
	await _save(func() -> Error: return Game.complete_segment(id, outputs, used))
	current_id = ""
	await _next()


# ---------------------------------------------------------------------------
# The Day 1 opening: the VN walks Game.chapters and calls the first shot
# ---------------------------------------------------------------------------
func _show_vn(file: String) -> void:
	var vn := VN_SCENE.instantiate()
	vn.begin({"file": file})
	var id := current_id
	vn.finished.connect(func(result: Dictionary) -> void: _complete(id, result), CONNECT_ONE_SHOT)
	vn.filed.connect(dossier.notify_filed)
	vn.term_clicked.connect(dossier.open)
	vn.call_requested.connect(func(call_name: String) -> void:
		if call_name == "first_shot":
			_show_first_shot())
	await _show(vn, story)


func _show_first_shot() -> void:
	var shot := FIRST_SHOT_SCENE.instantiate()
	shot.finished.connect(func(_result: Dictionary) -> void: _show_vn(""), CONNECT_ONE_SHOT)
	await _show(shot, world)


func _first_shot_due() -> bool:
	return Game.first_shot_pending or (Game.debug_first_shot and Game.first_shot_outcome.is_empty())


# ---------------------------------------------------------------------------
# Swapping and saving
# ---------------------------------------------------------------------------
func _show(node: Node, parent: Node) -> void:
	await transition.swap(func() -> void:
		if is_instance_valid(current):
			current.get_parent().remove_child(current)
			current.queue_free()
		current = node
		_refresh_phone(parent == world and current_id == "")
		parent.add_child(node))
	shown.emit(node)


## The phone is the only instrument on the HUD layer, and only the hub shows it.
## (The VN carries its own.) It is rebuilt each time so its day reads true.
func _refresh_phone(in_hub: bool) -> void:
	if is_instance_valid(_phone):
		_phone.queue_free()
	_phone = PHONE.new()
	hud.add_child(_phone)
	_phone_button.visible = in_hub and not Game.first_shot_outcome.is_empty()


func _save(action: Callable) -> void:
	while action.call() != OK:
		_say("Progress could not be saved. Click to retry.")
		await _clicked
	_say("")


func _say(text: String) -> void:
	_notice.text = text
	_notice.visible = text != ""


func _end_card() -> Control:
	var card := Label.new()
	card.name = "EndCard"
	card.text = "The calendar has run out.\n(Ending placeholder.)"
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return card


# ---------------------------------------------------------------------------
# Called by the Debug layer
# ---------------------------------------------------------------------------
func debug_skip() -> void:
	if current_id != "" and not transition.is_busy():
		_complete(current_id, {})


func debug_jump(day: int) -> void:
	if transition.is_busy():
		return
	await _save(func() -> Error: return Game.jump_to_day(day))
	current_id = ""
	_next()


func debug_toggle_flag(flag: String) -> void:
	if flag == "" or transition.is_busy():
		return
	Game.set_flag(flag, not Game.has_flag(flag))
	await _save(Game.save_campaign)
	if current_id == "":
		_next()


## Files every dossier entry, as if the story had shown them all.
func debug_file_all() -> void:
	for id in DOSSIER_DATA.all():
		Game.set_flag("file:" + id)
	_debug_dossier_changed("Filed all %d entries" % DOSSIER_DATA.all().size())


## Flips the entries between their before and after versions. Turning it off also
## clears the "already revised" mark, so turning it on again replays the reveal.
func debug_toggle_reveal() -> void:
	var on := not DOSSIER_DATA.revealed()
	Game.set_flag(DOSSIER_DATA.REVEAL_FLAG, on)
	if not on:
		Game.set_flag(DOSSIER_DATA.REVISED_FLAG, false)
	_debug_dossier_changed("Visor reveal " + ("on" if on else "off"))


## Saves only between segments: mid-VN the flags ride along with the next commit (spec §3).
func _debug_dossier_changed(what: String) -> void:
	print("Debug: ", what)
	if dossier.is_open():
		dossier.close()
	if current_id == "" and not transition.is_busy():
		await _save(Game.save_campaign)
		_dossier_closed()
