extends Node
## The browser demo shell (docs/demo_spec.md): title screen, controls screen, one segment,
## result screen with "Play again" and a feedback link. Generic: everything about a minigame
## comes from its entry in demo_entries.gd.
##
## It drives the segment as Main does (begin(args) before it enters the tree, then
## finished(result)), but never touches GameState or the save, has no debug panel and no
## F-keys. An exported demo starts here instead of Main: the `demo_<name>` preset sets
## `application/run/main_scene.demo` (see docs/demo_spec.md, "How a demo starts").

## Each screen as it appears: &"title", &"controls", &"segment", &"result".
signal shown(screen: StringName)

const ENTRIES: Dictionary = preload("res://demo/demo_entries.gd").ENTRIES
## PLACEHOLDER: Wesley supplies the feedback form's URL. While empty, the result screen
## shows the button disabled with "Feedback link coming soon".
const FEEDBACK_URL := ""
## Written by tools/export_demo.ps1 just before an export ("2026-11-17 c9ed6d6"); git-ignored.
const STAMP_FILE := "res://demo/build_stamp.txt"

const BG := Color(0.055, 0.05, 0.05)
const INK := Color(0.92, 0.89, 0.84)
const MUTED := Color(0.62, 0.58, 0.53)
const ACCENT := Color(0.86, 0.66, 0.32)

## Which entry to play. Empty: chosen from the export feature, then `-- --demo=<name>`,
## then the first entry. Set it before the shell enters the tree to force one (tests).
var demo := ""
var entry: Dictionary
var screen: StringName
var segment: Node
var result: Dictionary
var stamp := ""

@onready var _world: Node = $World
@onready var _ui: CanvasLayer = $UI
@onready var _transition: CanvasLayer = $Transition

var _page: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	if demo == "":
		demo = pick()
	entry = ENTRIES.get(demo, {})
	if entry.is_empty():
		push_error("DemoShell: no demo entry named %s" % demo)
		return
	stamp = read_stamp()
	print("DemoShell: %s (%s)" % [demo, stamp])
	_show_title()


static func pick() -> String:
	for name: String in ENTRIES:
		if OS.has_feature("demo_" + name):
			return name
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo="):
			return arg.trim_prefix("--demo=")
	return ENTRIES.keys()[0]


static func read_stamp() -> String:
	if FileAccess.file_exists(STAMP_FILE):
		var text := FileAccess.get_file_as_string(STAMP_FILE).strip_edges()
		if text != "":
			return text
	return "dev build"


# ---------------------------------------------------------------------------
# Flow
# ---------------------------------------------------------------------------
## Title -> controls.
func to_controls() -> void:
	await _transition.swap(_show_controls)


## Controls or result -> a fresh run of the segment.
func play() -> void:
	await _transition.swap(_start_segment)
	_emit(&"segment")


## Result -> title.
func to_title() -> void:
	await _transition.swap(_show_title)


func _start_segment() -> void:
	_set_page(null)
	_free_segment()
	segment = load(str(entry.segment)).instantiate()
	if segment.has_method("begin"):
		segment.begin(Dictionary(entry.get("args", {})).duplicate(true))
	segment.finished.connect(_on_finished, CONNECT_ONE_SHOT)
	_world.add_child(segment)


func _on_finished(r: Dictionary) -> void:
	result = r
	await _transition.swap(func() -> void:
		_free_segment()
		# A segment may leave these behind; the shell's screens need neither.
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_result())


func _free_segment() -> void:
	if segment != null and is_instance_valid(segment):
		# Leave the tree now, not at the end of the frame, so a fresh run's _enter_tree
		# never overlaps the old one's _exit_tree.
		_world.remove_child(segment)
		segment.queue_free()
	segment = null


func _emit(s: StringName) -> void:
	screen = s
	shown.emit(s)


# ---------------------------------------------------------------------------
# Screens
# ---------------------------------------------------------------------------
func _show_title() -> void:
	var col := _column()
	col.add_child(_label("WAR IDOL  ·  PLAYTEST DEMO", 16, ACCENT))
	col.add_child(_label(str(entry.title), 48, INK))
	col.add_child(_label(str(entry.get("blurb", "")), 18, MUTED))
	col.add_child(_gap(24))
	var start := _button(col, "Start", to_controls)
	var foot := _label("build " + stamp, 13, MUTED)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	foot.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_page.add_child(foot)
	start.grab_focus.call_deferred()
	_emit(&"title")


func _show_controls() -> void:
	var col := _column()
	col.add_child(_label("Controls", 32, INK))
	col.add_child(_gap(8))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 6)
	for pair: Array in entry.get("controls", []):
		var key := _label(str(pair[0]), 18, ACCENT)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(key)
		var what := _label(str(pair[1]), 18, INK)
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(what)
	col.add_child(grid)
	col.add_child(_gap(24))
	var go := _button(col, "Play", play)
	go.grab_focus.call_deferred()
	_emit(&"controls")


func _show_result() -> void:
	var col := _column()
	var outcome := str(result.get("outcome", ""))
	var headline := str(Dictionary(entry.get("outcomes", {})).get(outcome, outcome.capitalize()))
	col.add_child(_label(headline, 40, INK))
	for pair: Array in entry.get("results", []):
		if result.has(pair[0]):
			col.add_child(_label("%s: %s" % [pair[1], str(result[pair[0]])], 20, MUTED))
	col.add_child(_gap(24))
	var again := _button(col, "Play again", play)
	_button(col, "Title screen", to_title)
	var feedback := _button(col, "Send feedback", _open_feedback)
	if FEEDBACK_URL == "":
		feedback.text = "Feedback link coming soon"
		feedback.disabled = true
	col.add_child(_gap(8))
	col.add_child(_label("build " + stamp, 13, MUTED))
	again.grab_focus.call_deferred()
	_emit(&"result")


func _open_feedback() -> void:
	if FEEDBACK_URL != "":
		OS.shell_open(FEEDBACK_URL)


# ---------------------------------------------------------------------------
# Building blocks
# ---------------------------------------------------------------------------
func _set_page(page: Control) -> void:
	if _page != null:
		_ui.remove_child(_page)
		_page.queue_free()
	_page = page
	if page != null:
		_ui.add_child(page)


## A fresh full-screen page with a centred column; returns the column.
func _column() -> VBoxContainer:
	var page := ColorRect.new()
	page.color = BG
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_page(page)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)
	return col


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _gap(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
