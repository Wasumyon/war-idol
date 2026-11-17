extends CanvasLayer
## Debug builds only. F3 shows it: the saved state, a day jump, a flag toggle, a segment skip.
##
## Hotkeys work anywhere in a debug build, panel open or not. Each is also a button in the
## panel's bottom row, labelled with its key, so the panel is the list of them.
## To add one: a _hotkey() line in _ready() and a debug_* function on Main.
## F1–F2 and F12 are left free (help, OS screenshot tools); F3 is the panel itself.

var _state: Label
var _day: SpinBox
var _flag: LineEdit
var _hotkeys := {}   ## keycode -> Callable


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	hide()
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 8)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	_state = Label.new()
	_state.custom_minimum_size.x = 520
	_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_state.add_theme_font_size_override("font_size", 12)
	column.add_child(_state)
	var row := HBoxContainer.new()
	column.add_child(row)
	_day = SpinBox.new()
	_day.min_value = 1
	_day.max_value = 99
	row.add_child(_day)
	_button(row, "Jump to day", func() -> void: get_parent().debug_jump(int(_day.value)))
	_flag = LineEdit.new()
	_flag.placeholder_text = "flag"
	_flag.custom_minimum_size.x = 140
	row.add_child(_flag)
	_button(row, "Toggle flag", func() -> void: get_parent().debug_toggle_flag(_flag.text.strip_edges()))
	_button(row, "Skip segment", func() -> void: get_parent().debug_skip())
	var keys := HBoxContainer.new()
	column.add_child(keys)
	_hotkey(keys, KEY_F4, "File all entries", func() -> void: get_parent().debug_file_all())
	_hotkey(keys, KEY_F5, "Toggle visor reveal", func() -> void: get_parent().debug_toggle_reveal())
	_hotkey(keys, KEY_F6, "Play tunnel (hub only)", func() -> void: get_parent().debug_tunnel())


func _hotkey(parent: Node, key: Key, text: String, action: Callable) -> void:
	assert(not _hotkeys.has(key) and key != KEY_F3, "debug hotkey taken: " + OS.get_keycode_string(key))
	_hotkeys[key] = action
	_button(parent, "%s  %s" % [OS.get_keycode_string(key), text], action)


func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F3:
		visible = not visible
		_day.value = GameState.day
		get_viewport().set_input_as_handled()
	elif _hotkeys.has(event.keycode):
		_hotkeys[event.keycode].call()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible:
		_state.text = "%s\nsegment: %s | done: %s" % [
			GameState.debug_line(), get_parent().current_id, str(GameState.done_segments.keys())]
