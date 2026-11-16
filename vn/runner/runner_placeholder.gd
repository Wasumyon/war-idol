extends Control
## Stands in for the runner until it is ported. Same contract the runner will keep:
## begin({route, zone}) before entering the tree, then finished({outcome, ...}).

signal finished(result: Dictionary)

var _args := {}


func begin(args: Dictionary) -> void:
	_args = args


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#10191c")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var title := Label.new()
	title.text = "RUNNER PLACEHOLDER\nroute: %s   zone: %s" % [
		_args.get("route", "-"), _args.get("zone", "-")]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for outcome in ["good", "bad"]:
		var button := Button.new()
		button.name = outcome.capitalize()
		button.text = "%s run" % outcome.capitalize()
		button.pressed.connect(func() -> void: finished.emit({"outcome": outcome}))
		column.add_child(button)
