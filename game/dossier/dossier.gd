extends CanvasLayer
## The files screen: an overlay owned by Main, NOT a segment. Spec: docs/dossier_spec.md.
##
## open(id := "")  close()  notify_filed(id).  It sets flags in memory and never saves.
## It keeps processing while the tree is paused (Pause and the VN pause it).

signal closed

const DATA := preload("res://dossier/dossier_data.gd")
const GLITCH_FX := preload("res://dossier/glitch_effect.gd")
const REVEAL_FLAG := DATA.REVEAL_FLAG
const WALL := Color("#14131f")
const INK := Color("#e8f6f2")
const ACCENT := Color("#79ead1")
const MUTED := Color("#7d8a99")
const TAB_NEW := "new"
const TAB_ALL := "all"

var tab := TAB_NEW
var current := ""                  ## the entry shown, "" for none

var _root: Control
var _tabs := {}                    ## tab id -> Button
var _counter: Label
var _list: ItemList
var _list_ids: Array[String] = []
var _title: Label
var _details: VBoxContainer
var _image: TextureRect
var _stamp: Label
var _original: CheckButton
var _body: RichTextLabel
var _toast: Label
var _toast_tween: Tween
var _owns_pause := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()


# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------
func is_open() -> bool:
	return _root.visible


func open(id := "") -> void:
	var main := get_parent()
	if main != null and main.get("transition") != null and main.transition.is_busy():
		return
	DATA.sync_reveal()
	if not get_tree().paused:
		get_tree().paused = true
		_owns_pause = true
	_root.show()
	tab = TAB_NEW if id == "" and DATA.new_count() > 0 else TAB_ALL
	current = ""
	_refresh_tabs()
	_rebuild_list()
	if id != "" and DATA.is_filed(id):
		_show_entry(id)
		_select_in_list(id)
	elif not _list_ids.is_empty():
		_show_entry(_list_ids[0])
		_list.select(0)
	else:
		_show_entry("")
	_list.grab_focus()


func close() -> void:
	if not _root.visible:
		return
	_root.hide()
	if _owns_pause:
		get_tree().paused = false
		_owns_pause = false
	closed.emit()


## A short toast, shown whether or not the files are open.
func notify_filed(id: String) -> void:
	var e := DATA.entry(id)
	if e.is_empty():
		return
	_toast.text = "File added — %s" % e.title
	_toast.modulate.a = 1.0
	_toast.show()
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
	_toast_tween.tween_callback(_toast.hide)


## The ids the list shows for a tab ("new", "all" or a category id): filed entries only.
func list_ids(tab_id: String) -> Array[String]:
	DATA.sync_reveal()
	var out: Array[String] = []
	for id in DATA.ids_in("" if tab_id == TAB_NEW or tab_id == TAB_ALL else tab_id):
		if DATA.is_filed(id) and (tab_id != TAB_NEW or DATA.is_new(id)):
			out.append(id)
	return out


func show_tab(tab_id: String) -> void:
	tab = tab_id
	_refresh_tabs()
	_rebuild_list()
	if not _list_ids.is_empty():
		_show_entry(_list_ids[0])
		_list.select(0)
	else:
		_show_entry("")


func body_bbcode() -> String:
	return _body.text


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_step_tab(-1 if event.is_action_pressed("ui_left") else 1)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _step_tab(dir: int) -> void:
	var order := _tab_order()
	show_tab(order[posmod(order.find(tab) + dir, order.size())])


func _tab_order() -> Array[String]:
	var order: Array[String] = [TAB_NEW, TAB_ALL]
	for c in DATA.categories():
		order.append(c.id)
	return order


# ---------------------------------------------------------------------------
# Building the screen (placeholder look in the hub palette)
# ---------------------------------------------------------------------------
func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var wall := ColorRect.new()
	wall.color = WALL
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(wall)
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 14
	page.offset_right = -14
	page.offset_top = 10
	page.offset_bottom = -10
	page.add_theme_constant_override("separation", 6)
	_root.add_child(page)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	page.add_child(top)
	var back := Button.new()
	back.name = "Back"
	back.text = "← Back"
	back.pressed.connect(close)
	top.add_child(back)
	var heading := Label.new()
	heading.text = "FILES"
	heading.add_theme_color_override("font_color", ACCENT)
	top.add_child(heading)
	var group := ButtonGroup.new()
	for t in _tab_order():
		var b := Button.new()
		b.name = "Tab_" + t
		b.toggle_mode = true
		b.button_group = group
		b.text = "New" if t == TAB_NEW else ("All" if t == TAB_ALL else DATA.category_name(t))
		b.pressed.connect(show_tab.bind(t))
		top.add_child(b)
		_tabs[t] = b
	_counter = Label.new()
	_counter.add_theme_color_override("font_color", MUTED)
	page.add_child(_counter)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 12)
	page.add_child(split)
	_list = ItemList.new()
	_list.name = "List"
	_list.custom_minimum_size = Vector2(300, 0)
	_list.item_selected.connect(func(i: int) -> void: _show_entry(_list_ids[i]))
	split.add_child(_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	split.add_child(right)
	_title = Label.new()
	_title.name = "Title"
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", ACCENT)
	right.add_child(_title)
	right.add_child(HSeparator.new())
	var head_row := HBoxContainer.new()
	right.add_child(head_row)
	_details = VBoxContainer.new()
	_details.name = "Details"
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(_details)
	_image = TextureRect.new()
	_image.name = "Image"
	_image.custom_minimum_size = Vector2(180, 100)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head_row.add_child(_image)
	var stamp_row := HBoxContainer.new()
	right.add_child(stamp_row)
	_stamp = Label.new()
	_stamp.name = "Stamp"
	_stamp.text = "REVISED"
	_stamp.add_theme_color_override("font_color", Color("#ff5f8f"))
	stamp_row.add_child(_stamp)
	_original = CheckButton.new()
	_original.name = "Original"
	_original.text = "Original filing"
	_original.toggled.connect(func(_on: bool) -> void: _render())
	stamp_row.add_child(_original)
	_body = RichTextLabel.new()
	_body.name = "Body"
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_effects = [GLITCH_FX.new()]
	_body.meta_clicked.connect(func(meta: Variant) -> void: _follow(str(meta)))
	right.add_child(_body)

	_toast = Label.new()
	_toast.name = "Toast"
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 14
	_toast.add_theme_color_override("font_color", ACCENT)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.hide()
	add_child(_toast)


# ---------------------------------------------------------------------------
# Content
# ---------------------------------------------------------------------------
func _refresh_tabs() -> void:
	for t in _tabs:
		_tabs[t].set_pressed_no_signal(t == tab)


func _rebuild_list() -> void:
	_list.clear()
	_list_ids = list_ids(tab)
	for id in _list_ids:
		_list.add_item(_row_text(id))
	var scope := "" if tab == TAB_NEW or tab == TAB_ALL else tab
	var total := DATA.ids_in(scope).size()
	var filed := list_ids(TAB_ALL if scope == "" else scope).size()
	_counter.text = "%d new" % _list_ids.size() if tab == TAB_NEW else "%d / %d filed" % [filed, total]


func _row_text(id: String) -> String:
	var e := DATA.entry(id)
	return "%02d  %s%s" % [e.order, e.title, "  ●" if DATA.is_new(id) else ""]


func _select_in_list(id: String) -> void:
	var at := _list_ids.find(id)
	if at >= 0:
		_list.select(at)
		_list.ensure_current_is_visible()


## Opens one entry: it counts as read from here on. The New list keeps its row until the
## tab is left, so the list doesn't jump under the cursor.
func _show_entry(id: String) -> void:
	current = id
	_original.set_pressed_no_signal(false)
	if id != "":
		Game.set_flag("seen:" + id)
		var at := _list_ids.find(id)
		if at >= 0:
			_list.set_item_text(at, _row_text(id))
	_render()


func _render() -> void:
	var e := DATA.entry(current)
	_title.text = str(e.get("title", "")) if not e.is_empty() else "No files yet"
	for child in _details.get_children():
		_details.remove_child(child)
		child.queue_free()
	var revised: bool = not e.is_empty() and e.versioned and DATA.revealed()
	_stamp.visible = revised
	_original.visible = revised
	if e.is_empty():
		_image.texture = null
		_body.text = ""
		return
	for pair in e.info:
		var row := Label.new()
		row.text = "%s:  %s" % [pair[0], pair[1]]
		row.add_theme_color_override("font_color", MUTED)
		_details.add_child(row)
	_image.texture = _load_image(e.image)
	_image.visible = _image.texture != null
	_body.text = DATA.render_body(current, revised and _original.button_pressed)


func _load_image(name: String) -> Texture2D:
	if name == "":
		return null
	if name.begins_with("res://"):
		return load(name) as Texture2D
	for ext in DATA.IMG_EXTS:
		var p := "%s%s.%s" % [DATA.IMG_DIR, name, ext]
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
	return null


func _follow(id: String) -> void:
	if not DATA.is_filed(id):
		return
	tab = TAB_ALL
	_refresh_tabs()
	_rebuild_list()
	_show_entry(id)
	_select_in_list(id)
