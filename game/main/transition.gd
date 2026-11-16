extends CanvasLayer
## Fades to black, runs the swap, fades back. Input is swallowed meanwhile.
## Swaps asked for during a swap wait their turn.

signal idle

const TIME := 0.2

var _busy := false
var _rect: ColorRect


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func is_busy() -> bool:
	return _busy


func swap(change: Callable) -> void:
	while _busy:
		await idle
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade(1.0)
	change.call()
	await _fade(0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	idle.emit()


func _fade(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", alpha, TIME)
	await tween.finished


func _input(_event: InputEvent) -> void:
	if _busy:
		get_viewport().set_input_as_handled()
