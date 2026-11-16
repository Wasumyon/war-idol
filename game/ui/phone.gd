extends ColorRect

signal closed

const INK := Color("#e8f6f2")
const MUTED := Color("#a0b9bb")
const ACCENT := Color("#79ead1")
const STROKE := Color("#38545a")
const SCREEN := Color("#142227")

var _shortcuts: Dictionary = {}
var _wallet_balance: Label
var _content: VBoxContainer
var _close: Button
var _payment_error := false


func _ready() -> void:
	color = Color(0.012, 0.018, 0.024, 0.87)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shell := PanelContainer.new()
	center.add_child(shell)
	shell.custom_minimum_size = Vector2(776, 402)
	shell.add_theme_stylebox_override("panel", _surface(Color("#0c1419"), STROKE, 24, 10))
	var panels := HBoxContainer.new()
	panels.add_theme_constant_override("separation", 6)
	shell.add_child(panels)

	var left := _panel(panels)
	left.custom_minimum_size.x = 184
	var shortcuts := VBoxContainer.new()
	shortcuts.add_theme_constant_override("separation", 8)
	left.add_child(shortcuts)
	_label(shortcuts, "DAY %02d" % GameState.day, 14, ACCENT)
	_space(shortcuts)
	var group := ButtonGroup.new()
	for tab in ["Feed", "Wallet", "Shop"]:
		var button := _button(shortcuts, tab)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(_show_tab.bind(tab))
		_shortcuts[tab] = button
	_space(shortcuts, true)
	_label(shortcuts, "CASH AVAILABLE", 12, MUTED)
	_wallet_balance = _label(shortcuts, "", 27, INK)

	var hinge := PanelContainer.new()
	hinge.custom_minimum_size.x = 9
	hinge.add_theme_stylebox_override("panel", _surface(Color("#24363e"), Color("#52666b"), 4))
	panels.add_child(hinge)

	var right := _panel(panels)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	right.add_child(page)
	var toolbar := HBoxContainer.new()
	page.add_child(toolbar)
	_space(toolbar, true)
	_close = _button(toolbar, "Close  ×")
	_close.pressed.connect(_dismiss)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_content)


func open() -> void:
	_payment_error = false
	_show_tab("Wallet")
	show()
	_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_dismiss()


func _dismiss() -> void:
	hide()
	closed.emit()


func _show_tab(tab: String) -> void:
	_shortcuts[tab].set_pressed_no_signal(true)
	_wallet_balance.text = "$%d" % GameState.money
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_label(_content, tab, 32, INK)
	match tab:
		"Feed":
			_label(_content, "%d followers" % GameState.followers, 22, ACCENT)
			_add_receipt()
		"Wallet":
			_add_receipt()
			_space(_content)
			_label(_content, "Rig debt   $%d" % GameState.rig_debt, 22, INK)
			if GameState.first_installment_paid:
				_label(_content, "First installment paid  ·  $%d" % GameState.FIRST_INSTALLMENT, 17, ACCENT)
			else:
				var pay := _button(_content, "Pay $%d toward rig debt" % GameState.FIRST_INSTALLMENT)
				pay.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				pay.disabled = GameState.money < GameState.FIRST_INSTALLMENT or GameState.rig_debt < GameState.FIRST_INSTALLMENT
				pay.pressed.connect(_repay)
				if _payment_error:
					_label(_content, "Payment could not be saved. Try again.", 15, Color("#ffac9c"))
		"Shop":
			_label(_content, "Shop closed", 18, MUTED)


func _add_receipt() -> void:
	var capture := GameState.first_shot_outcome == "capture"
	var outcome := "Scout drone captured" if capture else "Scout drone missed"
	var receipt := _panel(_content)
	receipt.add_theme_stylebox_override("panel", _surface(Color("#1c3036"), STROKE, 10, 10))
	var details := VBoxContainer.new()
	receipt.add_child(details)
	_label(details, "First stream  /  " + outcome, 17, INK)
	_label(details, "+%d followers     +$%d donations" % [
		GameState.first_shot_receipt.get("followers", 0),
		GameState.first_shot_receipt.get("cash", 0),
	], 16, ACCENT)


func _repay() -> void:
	_payment_error = GameState.repay_first_installment() != OK
	_show_tab("Wallet")
	_shortcuts["Wallet"].grab_focus()


func _space(parent: Container, expand := false) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(1, 4)
	if expand:
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(gap)


func _panel(parent: Container) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _surface(SCREEN, STROKE, 15, 18))
	parent.add_child(panel)
	return panel


func _label(parent: Container, value: String, size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", ink)
	parent.add_child(label)
	return label


func _button(parent: Container, value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 38
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	button.add_theme_color_override("font_hover_pressed_color", ACCENT)
	button.add_theme_stylebox_override("normal", _surface(Color("#1a2b31"), STROKE, 7, 8))
	button.add_theme_stylebox_override("hover", _surface(Color("#264046"), ACCENT, 7, 8))
	button.add_theme_stylebox_override("pressed", _surface(Color("#21453f"), ACCENT, 7, 8))
	button.add_theme_stylebox_override("focus", _surface(Color.TRANSPARENT, ACCENT, 7))
	parent.add_child(button)
	return button


func _surface(fill: Color, border: Color, radius: int, padding := 0) -> StyleBoxFlat:
	var surface := StyleBoxFlat.new()
	surface.bg_color = fill
	surface.border_color = border
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(radius)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		surface.set_content_margin(side, padding)
	return surface
