extends Node2D
## Chip's first filming request. Records its own result (Game.record_first_shot is
## idempotent and gated on the chapter), then reports it with finished.

signal finished(result: Dictionary)

const BATTLEFIELD := preload("res://story/opener/io_battlefield.webp")
const FRAME := Vector2(960, 540)
const WINDOW := 5.0
const RADIUS := 29.0
const INK := Color("#d9f3ee")
const ACCENT := Color("#73ebd1")
const DARK := Color("#10191c")

var _elapsed := 0.0
var _subject := Vector2(175, 248)
var _resolved := false
var _captured := false
var _save_failed := false
var _leaving := false


func _ready() -> void:
	if not Game.first_shot_outcome.is_empty():
		_report.call_deferred()


func _process(delta: float) -> void:
	if not _resolved and not _leaving:
		_elapsed = minf(_elapsed + delta, WINDOW)
		_subject = Vector2(lerpf(175.0, 785.0, _elapsed / WINDOW), 248.0 + sin(_elapsed * 2.6) * 45.0)
		if _elapsed >= WINDOW:
			_resolve(false)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not event.is_action_pressed("opener_fire"):
		return
	get_viewport().set_input_as_handled()
	if not _resolved:
		_resolve(event.position.distance_to(_subject) <= RADIUS)
	elif _save_failed:
		_save_result()


func _resolve(captured: bool) -> void:
	_resolved = true
	_captured = captured
	_save_result()


func _save_result() -> void:
	_save_failed = Game.record_first_shot(_captured) != OK
	if _save_failed:
		return
	_leaving = true
	await get_tree().create_timer(0.65).timeout
	_report()


func _report() -> void:
	finished.emit({"outcome": Game.first_shot_outcome})


func _draw() -> void:
	var art_size := BATTLEFIELD.get_size()
	var art_draw_size := art_size * maxf(FRAME.x / art_size.x, FRAME.y / art_size.y)
	draw_texture_rect(BATTLEFIELD, Rect2((FRAME - art_draw_size) * 0.5, art_draw_size), false)
	draw_rect(Rect2(Vector2.ZERO, FRAME), Color(DARK, 0.48))
	draw_rect(Rect2(96, 95, 768, 343), Color(INK, 0.35), false, 1.0)
	draw_rect(Rect2(96, 95, 768 * (1.0 - _elapsed / WINDOW), 3), ACCENT)

	var cursor := get_local_mouse_position()
	var locked := cursor.distance_to(_subject) <= RADIUS
	var tint := ACCENT if locked else INK
	draw_colored_polygon(PackedVector2Array([
		_subject + Vector2(-22, 0), _subject + Vector2(-10, -9),
		_subject + Vector2(10, -9), _subject + Vector2(22, 0),
		_subject + Vector2(10, 9), _subject + Vector2(-10, 9),
	]), DARK)
	draw_circle(_subject, 4.0, Color("#ff896f"))
	draw_arc(_subject, RADIUS, 0, TAU, 48, tint, 2.0, true)

	if _resolved:
		var result := "CAPTURE SAVED" if _captured else "SHOT MISSED"
		if _save_failed:
			result = "SAVE FAILED · CLICK TO RETRY"
		_caption(result, 477, ACCENT)
	else:
		draw_circle(cursor, 13.0, DARK, false, 4.0, true)
		draw_circle(cursor, 13.0, tint, false, 2.0, true)
		_caption("SCOUT DRONE", 67, ACCENT)
		_caption("Aim at the drone and left-click to capture · One shot", 477, INK)


func _caption(line: String, baseline: float, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	var x := (FRAME.x - width) * 0.5
	draw_rect(Rect2(x - 12, baseline - 23, width + 24, 31), DARK)
	draw_string(font, Vector2(x, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)
