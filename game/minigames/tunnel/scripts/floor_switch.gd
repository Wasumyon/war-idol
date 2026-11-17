class_name FloorSwitch
extends Area2D
## A light-sensitive floor plate. Charges while the player's lamp shines on it
## (guard lanterns don't count). Opens the door at full charge, then drains
## without light and drops the door when empty.
##
## Node origin = centre of the plate on the floor line.

signal activated

@export var target_path: NodePath
@export var charge_time: float = 1.4
## Full speed near the lantern; a distant beam takes about seven seconds.
@export var full_charge_distance: float = 120.0
@export var slow_charge_distance: float = 470.0
@export_range(0.01, 1.0) var distant_charge_speed: float = 0.2
@export var drain_rate: float = 0.33
@export var drain_delay: float = 0.0
@export var plate_width: float = 70.0

var charge: float = 0.0
var is_on: bool = false
var _time: float = 0.0
var _glow: PointLight2D
var _dark_time: float = 0.0

const OFF_COLOR: Color = Color(0.55, 0.12, 0.08)
const CHARGE_COLOR: Color = Color(1.0, 0.75, 0.3)
const ON_COLOR: Color = Color(0.45, 1.0, 0.55)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b100  # light
	monitoring = true
	monitorable = false
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(plate_width, 24)
	shape.shape = rect
	shape.position = Vector2(0, -12)
	add_child(shape)

	_glow = PointLight2D.new()
	_glow.texture = preload("res://minigames/tunnel/art/light_radial.tres")
	_glow.position = Vector2(0, -10)
	_glow.texture_scale = 0.5
	_glow.energy = 0.5
	_glow.color = OFF_COLOR
	add_child(_glow)


func _physics_process(delta: float) -> void:
	_time += delta
	var lamp_strength: float = _lamp_strength_on_plate()
	if lamp_strength > 0.0:
		_dark_time = 0.0
		charge = minf(charge + delta * lamp_strength / charge_time, 1.0)
		if charge >= 1.0 and not is_on:
			_latch()
	else:
		var delay: float = drain_delay
		var previous_dark_time: float = _dark_time
		_dark_time += delta
		var drain_delta: float = maxf(_dark_time - delay, 0.0) - maxf(previous_dark_time - delay, 0.0)
		charge = maxf(charge - drain_rate * drain_delta, 0.0)
		if is_on and charge <= 0.0:
			is_on = false
			var target: Node = get_node_or_null(target_path)
			if target and target.has_method("close"):
				target.call("close")
	_glow.color = OFF_COLOR.lerp(ON_COLOR if is_on else CHARGE_COLOR, charge)
	_glow.energy = 0.5 + charge * 0.6
	queue_redraw()


func _lamp_strength_on_plate() -> float:
	var strength: float = 0.0
	for area: Area2D in get_overlapping_areas():
		if area.is_in_group("light_source") and not area.is_in_group("guard_light") and area.monitorable:
			var distance: float = global_position.distance_to(area.global_position)
			var proximity: float = clampf((distance - full_charge_distance) / maxf(slow_charge_distance - full_charge_distance, 1.0), 0.0, 1.0)
			strength = maxf(strength, lerpf(1.0, distant_charge_speed, proximity))
	return strength


func _latch() -> void:
	charge = 1.0
	is_on = true
	_glow.color = ON_COLOR
	_glow.energy = 0.9
	activated.emit()
	var target: Node = get_node_or_null(target_path)
	if target and target.has_method("open"):
		target.call("open")


func _draw() -> void:
	var w: float = plate_width
	# Housing and plate.
	draw_rect(Rect2(-w * 0.5 - 6, -10, w + 12, 10), Color(0.16, 0.15, 0.15))
	draw_rect(Rect2(-w * 0.5, -14, w, 6), Color(0.35, 0.33, 0.31))
	# Charge bar of cells across the plate.
	var cells: int = 7
	var lit: int = int(floor(charge * cells + 0.001))
	for i: int in cells:
		var x: float = -w * 0.5 + 5 + i * ((w - 10) / cells)
		var c: Color = OFF_COLOR.darkened(0.3)
		if is_on and i < lit:
			c = ON_COLOR
		elif i < lit:
			c = CHARGE_COLOR
		elif i == lit and charge > 0.0:
			c = OFF_COLOR.lerp(CHARGE_COLOR, 0.5 + 0.5 * sin(_time * 12.0))
		draw_rect(Rect2(x, -13, (w - 10) / cells - 2, 4), c)
