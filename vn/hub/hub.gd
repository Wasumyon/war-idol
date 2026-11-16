extends Control
## The hub: where the player decides what to do with a slot. PLACEHOLDER layout.
##
## Everything outside this scene sees only setup(offers) and the two signals, so the
## room can become 3D, or painted, without touching MainGame.

signal segment_chosen(id: String)
signal menu_requested
signal dossiers_requested   ## MainGame opens the files; the hub never touches that layer

const CALENDAR := preload("res://calendar/calendar.gd")
const DOSSIER_DATA := preload("res://dossier/dossier_data.gd")
const WALL := Color("#2b2740")
const INK := Color("#e8f6f2")
const ACCENT := Color("#79ead1")
const MUTED := Color("#7d8a99")

var _offers: Array[String] = []
var _dossier_button: Button
var _panel: PanelContainer
var _panel_title: Label
var _panel_body: VBoxContainer


func setup(offers: Array[String]) -> void:
	_offers = offers


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wall := ColorRect.new()
	wall.color = WALL
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wall)

	var header := Label.new()
	header.name = "Header"
	header.text = "DAY %02d  ·  %s" % [Game.day, CALENDAR.slot_name().to_upper()]
	header.position = Vector2(20, 14)
	header.add_theme_color_override("font_color", ACCENT)
	add_child(header)

	# Positions follow the bunker sketch: boards on the back wall, shelf under them,
	# the table in front, the menu in the corner.
	_hotspot("NewsStats", "NEWS / STATS", Rect2(250, 110, 170, 100), _open_stub.bind("News / Stats"))
	_dossier_button = _hotspot("Dossiers", "DOSSIERS", Rect2(420, 250, 130, 60), func() -> void: dossiers_requested.emit())
	refresh_dossier_count()
	_hotspot("Calendar", "CALENDAR\n%02d" % Game.day, Rect2(640, 130, 110, 80), _open_calendar)
	_hotspot("Missions", "MISSIONS", Rect2(290, 350, 380, 120), _open_missions)
	_hotspot("Menu", "MENU", Rect2(870, 484, 70, 40), func() -> void: menu_requested.emit())

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.position = Vector2(180, 70)
	_panel.custom_minimum_size = Vector2(600, 400)
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("#14131f")
	surface.border_color = MUTED
	surface.set_border_width_all(1)
	surface.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", surface)
	_panel.hide()
	add_child(_panel)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	var bar := HBoxContainer.new()
	column.add_child(bar)
	_panel_title = Label.new()
	_panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_title.add_theme_color_override("font_color", ACCENT)
	bar.add_child(_panel_title)
	var close := Button.new()
	close.text = "Close  ×"
	close.pressed.connect(_panel.hide)
	bar.add_child(close)
	_panel_body = VBoxContainer.new()
	_panel_body.name = "Body"
	_panel_body.add_theme_constant_override("separation", 8)
	_panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_panel_body)


func _hotspot(node_name: String, text: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.pressed.connect(action)
	add_child(button)
	return button


## DOSSIERS, or DOSSIERS · 3 NEW. MainGame calls this when the files close.
func refresh_dossier_count() -> void:
	var fresh := DOSSIER_DATA.new_count()
	_dossier_button.text = "DOSSIERS" if fresh == 0 else "DOSSIERS
· %d NEW" % fresh


func _open_panel(title: String) -> void:
	for child in _panel_body.get_children():
		_panel_body.remove_child(child)
		child.queue_free()
	_panel_title.text = title
	_panel.show()


func _open_missions() -> void:
	_open_panel("MISSIONS  ·  %s" % CALENDAR.slot_name().to_upper())
	for id in _offers:
		var seg := CALENDAR.segment(id)
		var button := Button.new()
		button.name = id
		button.text = "%s\n%s" % [seg.get("title", id), seg.get("blurb", "")]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void: segment_chosen.emit(id))
		_panel_body.add_child(button)


func _open_calendar() -> void:
	_open_panel("CALENDAR")
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_panel_body.add_child(grid)
	for day in range(1, CALENDAR.DATA.LAST_DAY + 1):
		var cell := Label.new()
		cell.custom_minimum_size = Vector2(64, 52)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.text = "%02d" % day
		if CALENDAR.is_checkpoint(day):
			cell.text += "\ncheckpoint"
			cell.add_theme_font_size_override("font_size", 11)
		var tint := INK
		if day < Game.day:
			tint = MUTED
		elif day == Game.day:
			tint = ACCENT
			cell.text = "> " + cell.text
		cell.add_theme_color_override("font_color", tint)
		grid.add_child(cell)


func _open_stub(title: String) -> void:
	_open_panel(title.to_upper())
	var note := Label.new()
	note.text = "Nothing filed yet."
	note.add_theme_color_override("font_color", MUTED)
	_panel_body.add_child(note)
