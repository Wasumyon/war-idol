extends CanvasLayer
## Tunnel's pause UI, a child of TunnelSegment (once the "PauseMenu" autoload). Its controls
## keep responding while the room is frozen. It handles Esc inside the tunnel's viewport,
## which marks the event handled for Main too, so Main's own pause stays shut.

const GOLD := Color(0.89, 0.73, 0.48)
const INK := Color(0.93, 0.89, 0.81)
const MUTED := Color(0.73, 0.68, 0.61)
const BORDER := Color(0.32, 0.26, 0.20)
const CONTROLS := [
	["A / D", "Move"],
	["Shift", "Sprint"],
	["Space", "Toggle lantern"],
	["W", "Hide in cover"],
	["E", "Interact"],
	["R", "Restart checkpoint"],
	["Esc", "Pause / resume"],
]

var _overlay: ColorRect
var _heading: Label
var _resume: Button
var _volume: HSlider
var _volume_percent: Label
var _assist: CheckButton
var _restart: Button
var _title: Button
var _at_title: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	_overlay = ColorRect.new()
	_overlay.color = Color(0.025, 0.02, 0.015, 0.92)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	var surface := _box(Color(0.10, 0.09, 0.075), BORDER)
	surface.content_margin_left = 36
	surface.content_margin_right = 36
	surface.content_margin_top = 28
	surface.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", surface)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	panel.add_child(content)
	_heading = _label("Paused", 32, GOLD)
	content.add_child(_heading)
	_add_rule(content, Vector2(0, 1))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	content.add_child(columns)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size.x = 320
	menu.add_theme_constant_override("separation", 12)
	columns.add_child(menu)
	_resume = _button(menu, "Resume", _on_resume)
	_build_volume(menu)
	_assist = CheckButton.new()
	_assist.text = "Assist: invincibility"
	_assist.custom_minimum_size.y = 38
	_assist.toggled.connect(TunnelManager.i.set_invincibility)
	menu.add_child(_assist)
	_restart = _button(menu, "Restart room", _on_restart)
	_title = _button(menu, "Return to title", _on_title)
	_add_rule(columns, Vector2(1, 0))
	_build_controls(columns)
	_overlay.hide()


func _box(fill: Color, edge: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style


func _label(caption: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_rule(parent: Control, minimum: Vector2) -> void:
	var rule := ColorRect.new()
	rule.color = BORDER
	rule.custom_minimum_size = minimum
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)


func _build_volume(menu: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 42
	row.add_theme_constant_override("separation", 12)
	menu.add_child(row)
	row.add_child(_label("Volume", 18, INK))
	_volume = HSlider.new()
	_volume.max_value = 100
	_volume.step = 1
	_volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume.accessibility_name = "Master volume"
	var track := _box(Color(0.22, 0.18, 0.14))
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = GOLD
	_volume.add_theme_stylebox_override("slider", track)
	_volume.add_theme_stylebox_override("grabber_area", fill)
	_volume.add_theme_stylebox_override("grabber_area_highlight", fill)
	_volume.value_changed.connect(_on_volume_changed)
	row.add_child(_volume)
	_volume_percent = _label("", 16, GOLD)
	_volume_percent.custom_minimum_size.x = 52
	_volume_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_volume_percent)


func _build_controls(columns: HBoxContainer) -> void:
	var reference := VBoxContainer.new()
	reference.custom_minimum_size.x = 300
	reference.add_theme_constant_override("separation", 10)
	columns.add_child(reference)
	reference.add_child(_label("Controls", 22, GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 10)
	reference.add_child(grid)
	for binding: Array in CONTROLS:
		grid.add_child(_label(binding[0], 18, INK))
		grid.add_child(_label(binding[1], 18, MUTED))


func _button(parent: Control, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 44
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", _box(Color(0.16, 0.14, 0.11)))
	button.add_theme_stylebox_override("hover", _box(Color(0.24, 0.19, 0.13), BORDER))
	button.add_theme_stylebox_override("pressed", _box(Color(0.28, 0.22, 0.15), GOLD))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, GOLD))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if _at_title or TunnelManager.i.is_transitioning():
			return
		if _overlay.visible:
			close()
		elif not get_tree().paused:
			open()


func open() -> void:
	var percent := 0.0 if AudioServer.is_bus_mute(0) else db_to_linear(AudioServer.get_bus_volume_db(0)) * 100.0
	_volume.set_value_no_signal(percent)
	_volume_percent.text = "%d%%" % int(_volume.value)
	_assist.set_pressed_no_signal(TunnelManager.i.god_mode)
	_overlay.show()
	get_tree().paused = true
	_resume.grab_focus()


func _on_volume_changed(percent: float) -> void:
	AudioServer.set_bus_mute(0, percent == 0)
	if percent > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(percent / 100.0))
	_volume_percent.text = "%d%%" % int(percent)


func close() -> void:
	_overlay.hide()
	get_tree().paused = false


func _on_resume() -> void:
	if _at_title:
		_at_title = false
		_heading.text = "Paused"
		_resume.text = "Resume"
		_restart.show()
		_title.show()
		close()
		TunnelManager.i.restart_run("res://minigames/tunnel/scenes/intro.tscn")
	else:
		close()


func _on_restart() -> void:
	TunnelManager.i.clear_checkpoint()
	TunnelManager.i.set_death_line("")
	close()
	TunnelManager.i.respawn_player()


func _on_title() -> void:
	_at_title = true
	_heading.text = "ESCAPE WAR IDOL"
	_resume.text = "Start game"
	_restart.hide()
	_title.hide()
	_resume.grab_focus()
