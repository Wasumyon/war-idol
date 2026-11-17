extends CanvasLayer
## Per-chamber HUD: vignette, lives and messages.

class HeartIcon extends Control:
	var filled: bool = true:
		set(value):
			filled = value
			queue_redraw()

	func _draw() -> void:
		var shape := PackedVector2Array([
			Vector2(14, 8), Vector2(11, 5), Vector2(7, 4), Vector2(4, 5),
			Vector2(2, 8), Vector2(2, 12), Vector2(4, 16), Vector2(8, 20),
			Vector2(14, 25), Vector2(20, 20), Vector2(24, 16), Vector2(26, 12),
			Vector2(26, 8), Vector2(24, 5), Vector2(21, 4), Vector2(17, 5),
		])
		draw_colored_polygon(shape, Color("e07a6d") if filled else Color("201715"))
		shape.append(shape[0])
		draw_polyline(shape, Color("4b2927") if filled else Color("ad948b"), 1.6, true)

@onready var _hint: Label = $HUD/HintLabel
@onready var _message: Label = $HUD/MessageLabel
@onready var _lives: HBoxContainer = $HUD/Lives

func _ready() -> void:
	add_to_group("hud")
	_hint.text = ""
	_hint.hide()
	_message.modulate.a = 0.0
	for i: int in TunnelManager.MAX_LIVES:
		var heart := HeartIcon.new()
		heart.custom_minimum_size = Vector2(28, 28)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lives.add_child(heart)
	TunnelManager.i.lives_changed.connect(_show_lives)
	_show_lives(TunnelManager.i.lives)


func _show_lives(remaining: int) -> void:
	for i: int in _lives.get_child_count():
		var heart: HeartIcon = _lives.get_child(i)
		heart.filled = i < remaining


func set_hint(value: String) -> void:
	_hint.text = value
	_hint.visible = not value.is_empty()


func show_message(value: String) -> void:
	_message.text = value
	var tween: Tween = create_tween()
	tween.tween_property(_message, "modulate:a", 1.0, 1.2)
