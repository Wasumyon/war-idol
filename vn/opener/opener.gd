extends Node2D

enum Phase { CONTACT, INCOMING, IMPACT, SETBACK, HANDOFF }

const BATTLEFIELD := preload("res://opener/io_battlefield.webp")
const FRAME := Vector2(960, 540)
const FIRE_POINT := Vector2(480, 490)
const TARGET_RADIUS := 30.0
const WARNING_TIME := 2.25
const DODGE_TIME := 0.18
const IMPACT_TIME := 0.8
const SETBACK_TIME := 1.9
const AMBER := Color("#ffd08a")
const RED := Color("#ff7770")
const PALE := Color("#d9f3ee")
const DARK := Color("#11191d")

var _phase := Phase.CONTACT
var _elapsed := 0.0
var _target := Vector2(480, 218)
var _shot := Vector2.ZERO
var _shot_flash := 0.0
var _dodge_elapsed := 0.0
var _dodged := false
var _save_failed := false


func _ready() -> void:
	if Game.load_error != OK:
		_enter(Phase.HANDOFF)
	elif Game.first_shot_pending or (Game.debug_first_shot and Game.first_shot_outcome.is_empty()):
		_handoff.call_deferred(Game.FIRST_SHOT_SCENE)
	elif Game.has_checkpoint:
		_handoff.call_deferred(Game.VN_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if _save_failed and event.is_action_pressed("opener_fire"):
		get_viewport().set_input_as_handled()
		_save_and_handoff()
	elif _phase == Phase.CONTACT and event is InputEventMouseButton and event.is_action_pressed("opener_fire"):
		get_viewport().set_input_as_handled()
		_shot = event.position
		_shot_flash = 0.13
		if _shot.distance_to(_target) <= TARGET_RADIUS:
			_enter(Phase.INCOMING)
	elif _phase == Phase.INCOMING and event.is_action_pressed("opener_dodge"):
		get_viewport().set_input_as_handled()
		if _dodge_elapsed == 0.0:
			_dodge_elapsed = 0.001


func _process(delta: float) -> void:
	_elapsed += delta
	_shot_flash = maxf(0.0, _shot_flash - delta)
	if _dodge_elapsed > 0.0:
		_dodge_elapsed += delta
	match _phase:
		Phase.CONTACT:
			_target.x = 480.0 + sin(_elapsed * 1.5) * 104.0
			_target.y = 218.0 + sin(_elapsed * 2.1) * 15.0
		Phase.INCOMING:
			if _elapsed >= WARNING_TIME:
				_dodged = _dodge_elapsed >= DODGE_TIME
				_enter(Phase.IMPACT)
		Phase.IMPACT:
			if _elapsed >= IMPACT_TIME:
				_enter(Phase.SETBACK)
		Phase.SETBACK:
			if _elapsed >= SETBACK_TIME:
				_save_and_handoff()
	queue_redraw()


func _save_and_handoff() -> void:
	_enter(Phase.HANDOFF)
	_save_failed = Game.save_campaign() != OK
	if not _save_failed:
		_handoff(Game.VN_SCENE)


func _handoff(path: String) -> void:
	var result := get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("Opener: could not open %s (%s)" % [path, error_string(result)])


func _enter(phase: Phase) -> void:
	_phase = phase
	_elapsed = 0.0


func _draw() -> void:
	var art_size := BATTLEFIELD.get_size()
	var scale_to_cover := maxf(FRAME.x / art_size.x, FRAME.y / art_size.y)
	var art_draw_size := art_size * scale_to_cover
	draw_texture_rect(BATTLEFIELD, Rect2((FRAME - art_draw_size) * 0.5, art_draw_size), false)
	draw_rect(Rect2(Vector2.ZERO, FRAME), Color(0.03, 0.05, 0.07, 0.32))

	var status := ""
	var instruction := ""
	var accent := PALE
	match _phase:
		Phase.CONTACT:
			_draw_target()
			_draw_reticle()
			status = "HOSTILE DRONE"
			instruction = "Aim and left-click to fire"
		Phase.INCOMING:
			var remaining := 1.0 - _elapsed / WARNING_TIME
			_draw_strike_zone(0.16 + (1.0 - remaining) * 0.15)
			draw_rect(Rect2(380, 91, 200 * remaining, 3), RED)
			status = "INCOMING STRIKE"
			instruction = "Shift to dodge" if _dodge_elapsed == 0.0 else "Dodging"
			accent = RED
		Phase.IMPACT:
			_draw_strike_zone(0.45 * (1.0 - _elapsed / IMPACT_TIME))
			status = "STRIKE EVADED" if _dodged else "DIRECT HIT"
			accent = PALE if _dodged else RED
		Phase.SETBACK, Phase.HANDOFF:
			status = "SECOND STRIKE" if _elapsed < 0.55 else "RIG OFFLINE"
			accent = RED
	if Game.load_error != OK:
		status = "CAMPAIGN SAVE COULD NOT BE LOADED"
	elif _save_failed:
		status = "CAMPAIGN SAVE FAILED"
		instruction = "Click to retry"

	if _shot_flash > 0.0:
		draw_line(FIRE_POINT, _shot, AMBER, 2.0, true)
		draw_circle(_shot, 5.0, AMBER)

	var shift := smoothstep(0.0, DODGE_TIME, _dodge_elapsed)
	var cockpit := FIRE_POINT + Vector2(250.0 * shift, 0)
	if _phase == Phase.SETBACK:
		cockpit.y += 18.0 * smoothstep(0.0, 0.23, _elapsed)
	draw_colored_polygon(PackedVector2Array([
		cockpit + Vector2(-125, 50), cockpit + Vector2(-61, -12),
		cockpit + Vector2(61, -12), cockpit + Vector2(125, 50),
	]), DARK)
	draw_line(cockpit + Vector2(-61, -12), cockpit + Vector2(61, -12), accent, 2.0, true)

	if _phase == Phase.SETBACK:
		var darkness := smoothstep(0.0, SETBACK_TIME, _elapsed)
		draw_rect(Rect2(Vector2.ZERO, FRAME), Color(RED, 0.18 * (1.0 - smoothstep(0.0, 0.3, _elapsed))))
		draw_rect(Rect2(Vector2.ZERO, FRAME), Color(0.02, 0.025, 0.03, 0.85 * darkness))
		accent.a = 1.0 - smoothstep(1.05, SETBACK_TIME, _elapsed)
	_draw_caption(status, 66, 22, accent)
	if not instruction.is_empty():
		_draw_caption(instruction, 443, 19, PALE)


func _draw_target() -> void:
	var outline := PackedVector2Array([
		_target + Vector2(-24, 0), _target + Vector2(-12, -12),
		_target + Vector2(12, -12), _target + Vector2(24, 0),
		_target + Vector2(12, 12), _target + Vector2(-12, 12),
	])
	draw_colored_polygon(outline, DARK)
	draw_circle(_target, 6.0, RED, true, -1.0, true)
	draw_arc(_target, TARGET_RADIUS, 0.0, TAU, 48, AMBER, 2.0, true)


func _draw_reticle() -> void:
	var cursor := get_local_mouse_position()
	var ink := AMBER if cursor.distance_to(_target) <= TARGET_RADIUS else PALE
	draw_circle(cursor, 12.0, DARK, false, 4.0, true)
	draw_circle(cursor, 12.0, ink, false, 1.5, true)
	draw_circle(cursor, 2.0, ink)


func _draw_strike_zone(alpha: float) -> void:
	var zone := PackedVector2Array([
		Vector2(470, 155), Vector2(490, 155),
		Vector2(600, 540), Vector2(360, 540),
	])
	draw_colored_polygon(zone, Color(RED, alpha))
	draw_line(zone[0], zone[3], RED, 2.0, true)
	draw_line(zone[1], zone[2], RED, 2.0, true)


func _draw_caption(line: String, baseline: float, size: int, ink: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := (FRAME.x - width) * 0.5
	draw_rect(Rect2(x - 14, baseline - size - 4, width + 28, size + 12), Color(DARK, 0.91 * ink.a))
	draw_string(font, Vector2(x, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
