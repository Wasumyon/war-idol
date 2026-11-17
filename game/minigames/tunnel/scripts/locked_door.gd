class_name LockedDoor
extends Node2D
## A steel shutter that blocks the tunnel (solid on layer 1) until something
## calls open(), then rolls up into the ceiling and stops blocking.
## Has a status lamp: red while locked, green once opened.
##
## Node origin = bottom centre of the shutter on the floor line.

signal opened

@export var width: float = 46.0
@export var height: float = 440.0
@export var open_time: float = 1.6
@export var close_time: float = 0.55
@export var starts_open: bool = false
## Some gates also block guard sight while closed.
@export var blocks_sight: bool = false

var is_open: bool = false
## 0 = closed, 1 = fully rolled up.
var _lift: float = 0.0
var _shape: CollisionShape2D
var _lamp: PointLight2D
var _tween: Tween
var _closing: bool = false

const STEEL: Color = Color(0.30, 0.29, 0.28)
const STEEL_DARK: Color = Color(0.17, 0.16, 0.16)
const RUST: Color = Color(0.55, 0.28, 0.1)
const MOVEMENT_LAYER: int = 1 << 3


func _ready() -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = MOVEMENT_LAYER | 1 if blocks_sight else MOVEMENT_LAYER
	body.collision_mask = 0
	add_child(body)
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	_shape = CollisionShape2D.new()
	_shape.shape = rect
	_shape.position = Vector2(0, -height * 0.5)
	body.add_child(_shape)

	_lamp = PointLight2D.new()
	_lamp.texture = preload("res://art/light_radial.tres")
	_lamp.position = Vector2(-width * 0.5 - 18, -190)
	_lamp.texture_scale = 0.35
	_lamp.energy = 0.9
	_lamp.color = Color(1, 0.15, 0.1)
	add_child(_lamp)

	if starts_open:
		is_open = true
		_lift = 1.0
		_shape.disabled = true
		_lamp.color = Color(0.3, 1, 0.4)


func open() -> void:
	if is_open:
		return
	is_open = true
	_closing = false
	if _tween:
		_tween.kill()
	_lamp.color = Color(0.3, 1, 0.4)
	var tween: Tween = create_tween()
	_tween = tween
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "_lift", 1.0, open_time)
	# Stop blocking once it has cleared head height.
	tween.parallel().tween_callback(func() -> void: _shape.set_deferred("disabled", true)).set_delay(open_time * 0.45)
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_closing = true
	# A partially opened door may still have its solid collider enabled.
	# Keep it out of physics recovery until the lethal drop is finished.
	_shape.set_deferred("disabled", true)
	if _tween:
		_tween.kill()
	_lamp.color = Color(1, 0.15, 0.1)
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "_lift", 0.0, close_time)
	_tween.tween_callback(func() -> void:
		_check_crush()
		_clear_guard_from_doorway()
		_shape.set_deferred("disabled", false)
		_closing = false
	)


func _physics_process(_delta: float) -> void:
	if _closing:
		_check_crush()


func _check_crush() -> void:
	# Test the actual player collider against the descending shutter, including
	# its final position so the last frame of a fast drop cannot miss a crush.
	var player := get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(player):
		return
	var collider: CollisionShape2D = player.get_node("BodyCollider") as CollisionShape2D
	var shutter: Rect2 = Rect2(Vector2(-width * 0.5, -height), Vector2(width, height * (1.0 - _lift)))
	var bounds: Rect2 = collider.shape.get_rect()
	var player_bounds: Rect2 = global_transform.affine_inverse() * collider.global_transform * bounds
	if shutter.intersects(player_bounds):
		player.kill(self, "", true)


func _clear_guard_from_doorway() -> void:
	# If the gate drops mid-step, seat the guard on his side of the centreline.
	# Otherwise physics recovery could move an overlapping guard through the gate.
	for node: Node in get_tree().get_nodes_in_group("guard"):
		if node is EnemyGuard:
			var guard: EnemyGuard = node
			var local: Vector2 = to_local(guard.global_position)
			var clearance: float = width * 0.5 + EnemyGuard.BODY_HALF_WIDTH + 1.0
			if absf(local.x) < clearance and absf(local.y) <= 10.0:
				local.x = clearance if local.x >= 0.0 else -clearance
				guard.global_position = to_global(local)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Frame posts stay put.
	draw_rect(Rect2(-width * 0.5 - 10, -height, 8, height), STEEL_DARK)
	draw_rect(Rect2(width * 0.5 + 2, -height, 8, height), STEEL_DARK)
	# Status lamp housing.
	draw_rect(Rect2(-width * 0.5 - 24, -196, 10, 12), STEEL_DARK)
	draw_rect(Rect2(-width * 0.5 - 22, -194, 6, 8), _lamp.color if _lamp else Color.RED)
	# The crossbars roll up, leaving the bottom gap growing.
	var visible_h: float = height * (1.0 - _lift)
	if visible_h < 2.0:
		return
	var top: float = -height
	var bottom: float = top + visible_h
	_draw_grille(top, bottom)
	# Bottom bar with a rust stripe.
	draw_rect(Rect2(-width * 0.5 - 2, bottom - 10, width + 4, 10), STEEL_DARK)
	draw_rect(Rect2(-width * 0.5, bottom - 7, width, 3), RUST)


func _draw_grille(top: float, bottom: float) -> void:
	var left: float = -width * 0.5 + 3.0
	var right: float = -left
	var diamond_height: float = width * 1.14
	var y: float = bottom - 7.0
	while y > top:
		var upper: float = maxf(y - diamond_height, top)
		var fraction: float = (y - upper) / diamond_height
		var down_left := Vector2(left, y)
		var down_right := Vector2(right, y)
		var up_right := Vector2(lerpf(left, right, fraction), upper)
		var up_left := Vector2(lerpf(right, left, fraction), upper)
		draw_line(down_left, up_right, STEEL_DARK, 7.0, true)
		draw_line(down_right, up_left, STEEL_DARK, 7.0, true)
		draw_line(down_left, up_right, STEEL.lightened(0.15), 4.0, true)
		draw_line(down_right, up_left, STEEL, 4.0, true)
		y -= diamond_height
	draw_line(Vector2(left, top), Vector2(left, bottom), STEEL, 7.0)
	draw_line(Vector2(right, top), Vector2(right, bottom), STEEL, 7.0)
