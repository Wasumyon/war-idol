extends CanvasLayer
## Esc pauses the tree. This layer keeps processing while everything else stops.
## It sits first under Main so it sees Esc last: an open phone closes first.

var _resume: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_resume = Button.new()
	_resume.name = "Resume"
	_resume.text = "Resume"
	_resume.pressed.connect(close)
	column.add_child(_resume)
	var files := Button.new()
	files.name = "Files"
	files.text = "Files"
	files.pressed.connect(func() -> void: get_parent().dossier.open())
	column.add_child(files)
	var quit := Button.new()
	quit.name = "Quit"
	quit.text = "Quit to desktop"
	quit.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if visible:
			close()
		else:
			open()


func open() -> void:
	if get_parent().transition.is_busy():
		return
	show()
	get_tree().paused = true
	_resume.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false
