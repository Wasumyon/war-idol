class_name SpotlightSweep
extends Node2D
## Chamber 3's searchlight: a huge lamp on a far tower whose pool of light
## sweeps the bridge back and forth (ping-pong, short pause at each end).
## If the pool covers the player and he isn't hidden, a short grace meter
## fills; when it's full he's spotted and loses a life.
## Standing in a pillar's shadow or actively hiding makes the light pass harmlessly.
## The pool is drawn as a flat patch on the deck; pillars (shadow_spans) cut it,
## and the pool light skips anything on light_mask bit 2 (the pillars).
## Place this node at the chamber origin (0, 0): all xs are world-x and the
## floor line is y = 0.

signal spotted_player

## Where the lamp head sits (world).
@export var source: Vector2 = Vector2(2100, -620)
## Range of the pool's centre on the floor.
@export var sweep_left: float = 0.0
@export var sweep_right: float = 4250.0
@export var sweep_speed: float = 240.0
@export var end_pause: float = 1.2
@export var start_x: float = 4250.0
## 1 = starts moving right, -1 = left.
@export var start_dir: int = -1
## Half-width of the lit pool on the floor.
@export var pool_half_width: float = 130.0
## Seconds in the pool before he's spotted (a sliver of grace).
@export var catch_time: float = 0.25
## World-x spans (x = left, y = right) the pillars shade from the light.
@export var shadow_spans: PackedVector2Array = PackedVector2Array()
## Pool light layer: 1 (deck, player), not 2 (pillars).
@export_flags_2d_render var pool_light_mask: int = 1
## Strength of the big glow around the pool.
@export var glow_energy: float = 1.3
@export var glow_scale: float = 1.0
## Once he's spotted: silence, then a shot from the tower (seconds).
@export var shot_delay: float = 0.45
@export var after_shot: float = 0.25

const BEAM_COL: Color = Color(0.85, 0.92, 1.0, 0.16)
const CORE_COL: Color = Color(0.95, 0.97, 1.0, 0.12)
const LIGHT_TEX: Texture2D = preload("res://art/light_radial.tres")

var pool_x: float = 0.0
var _dir: int = -1
var _pause: float = 0.0
var _catch: float = 0.0
var _done: bool = false
var _shoot_t: float = -1.0
var _fired: bool = false
var _player: Player

var _beam: Polygon2D
var _core: Polygon2D
var _floor_light: PointLight2D
## The big menacing glow around the pool (lights the air and far wall, not
## the pillars, so it stops dead at their edges).
var _glow_light: PointLight2D
var _pool_root: Node2D
var _add: CanvasItemMaterial
var _head: Polygon2D
var _head_light: PointLight2D


func _ready() -> void:
	pool_x = clampf(start_x, sweep_left, sweep_right)
	_dir = 1 if start_dir >= 0 else -1
	_build()
	_update_visual()


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player

	if _shoot_t >= 0.0:
		pass  # the light holds on him
	elif _pause > 0.0:
		_pause -= delta
	else:
		pool_x += sweep_speed * float(_dir) * delta
		if pool_x >= sweep_right or pool_x <= sweep_left:
			pool_x = clampf(pool_x, sweep_left, sweep_right)
			_dir = -_dir
			_pause = end_pause

	if _shoot_t >= 0.0:
		_process_shot(delta)
	elif not _done:
		if player_in_light():
			_catch += delta
			if _catch >= catch_time:
				_spot()
		else:
			_catch = maxf(_catch - delta * 2.0, 0.0)
	_update_visual()


## Detection uses the same pillar shadow spans as the visible pool cutouts.
func player_in_light() -> bool:
	if _player == null or _player.is_dead or _player.is_hidden:
		return false
	var player_x: float = _player.global_position.x
	return absf(player_x - pool_x) <= pool_half_width and not _in_shadow(player_x)


func _spot() -> void:
	spotted_player.emit()
	if GameManager.god_mode:
		_catch = 0.0
		return
	_done = true
	# No warning, no voice: the light holds on him, then the tower fires.
	_player.freeze()
	_shoot_t = 0.0
	_fired = false


func _process_shot(delta: float) -> void:
	_shoot_t += delta
	_catch = catch_time  # keep the beam red
	if _player == null or _player.is_dead:
		return
	if not _fired and _shoot_t >= shot_delay:
		_fired = true
		GunshotFX.fire(get_tree().current_scene, source + Vector2(0, 14), _player.global_position + Vector2(0, -60))
		_player.hit_flash()
	if _fired and _shoot_t >= shot_delay + after_shot:
		_player.kill(self, "The pillars block the beam.\nI can wait in their shadow and\nmove when it sweeps past.")


func _update_visual() -> void:
	var l: float = pool_x - pool_half_width
	var r: float = pool_x + pool_half_width
	var s: Vector2 = source
	_beam.polygon = PackedVector2Array([s + Vector2(-26, 10), s + Vector2(26, 10), Vector2(r, 0), Vector2(l, 0)])
	_core.polygon = PackedVector2Array([s + Vector2(-10, 10), s + Vector2(10, 10), Vector2(pool_x + pool_half_width * 0.45, 0), Vector2(pool_x - pool_half_width * 0.45, 0)])
	var lit: float = _lit_fraction(l, r)
	_floor_light.position = Vector2(pool_x, -24)
	_floor_light.energy = 1.4 * lit
	_glow_light.position = Vector2(pool_x, -90)
	var t: float = clampf(_catch / catch_time, 0.0, 1.0)
	_beam.color = BEAM_COL.lerp(Color(1.0, 0.45, 0.35, 0.22), t)
	_update_pool(l, r, t)
	_head.rotation = (Vector2(pool_x, 0) - s).angle() - PI / 2.0


func _in_shadow(x: float) -> bool:
	for span: Vector2 in shadow_spans:
		if x >= span.x and x <= span.y:
			return true
	return false


## Fraction of the pool's width not shaded by a pillar.
func _lit_fraction(l: float, r: float) -> float:
	var n: int = 24
	var lit: int = 0
	for i: int in n:
		if not _in_shadow(lerpf(l, r, (float(i) + 0.5) / float(n))):
			lit += 1
	return float(lit) / float(n)


## The patch of light on the deck: a flat ellipse, with the pillar spans cut out.
func _update_pool(l: float, r: float, t: float) -> void:
	for c: Node in _pool_root.get_children():
		c.queue_free()
	var col: Color = Color(0.9, 0.95, 1.0, 0.28).lerp(Color(1.0, 0.5, 0.4, 0.32), t)
	var step: float = 8.0
	var run: Array[float] = []
	var x: float = l
	while x <= r + 0.01:
		if _in_shadow(x):
			_emit_run(run, col)
			run = []
		else:
			run.append(x)
		x += step
	_emit_run(run, col)


func _emit_run(xs: Array[float], col: Color) -> void:
	if xs.size() < 2:
		return
	var top: PackedVector2Array = PackedVector2Array()
	var bot: PackedVector2Array = PackedVector2Array()
	for x: float in xs:
		var u: float = (x - pool_x) / pool_half_width
		var h: float = 14.0 * sqrt(maxf(1.0 - u * u, 0.0))
		top.append(Vector2(x, -h))
		bot.append(Vector2(x, h * 0.6))
	bot.reverse()
	var poly: Polygon2D = Polygon2D.new()
	poly.material = _add
	poly.color = col
	poly.polygon = top + bot
	_pool_root.add_child(poly)


func _build() -> void:
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	_add = add
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_beam = Polygon2D.new()
	_beam.name = "Beam"
	_beam.material = add
	_beam.z_index = -2  # in front of the far backdrop, behind the pillars
	add_child(_beam)
	_core = Polygon2D.new()
	_core.name = "Core"
	_core.material = add
	_core.color = CORE_COL
	_core.z_index = -2
	add_child(_core)

	_floor_light = PointLight2D.new()
	_floor_light.name = "PoolLight"
	_floor_light.texture = LIGHT_TEX
	_floor_light.color = Color(0.85, 0.92, 1.0)
	_floor_light.energy = 1.4
	_floor_light.texture_scale = 1.0
	# Flattened so it lies on the deck instead of glowing up the walls.
	_floor_light.scale = Vector2(1.25, 0.4)
	_floor_light.range_item_cull_mask = pool_light_mask
	add_child(_floor_light)

	_glow_light = PointLight2D.new()
	_glow_light.name = "GlowLight"
	_glow_light.texture = LIGHT_TEX
	_glow_light.color = Color(0.85, 0.92, 1.0)
	_glow_light.energy = glow_energy
	_glow_light.texture_scale = glow_scale
	_glow_light.range_item_cull_mask = pool_light_mask
	add_child(_glow_light)

	# The patch on the deck sits over the deck edge, behind the player.
	_pool_root = Node2D.new()
	_pool_root.name = "Pool"
	_pool_root.z_index = 3
	add_child(_pool_root)

	# The lamp head on its far tower.
	_head = Polygon2D.new()
	_head.name = "LampHead"
	_head.position = source
	_head.z_index = -3
	_head.color = Color(0.2, 0.2, 0.22)
	_head.polygon = PackedVector2Array([Vector2(-34, -24), Vector2(34, -24), Vector2(26, 14), Vector2(-26, 14)])
	add_child(_head)
	var lens: Polygon2D = Polygon2D.new()
	lens.material = add
	lens.color = Color(0.95, 0.97, 1.0, 0.9)
	lens.polygon = PackedVector2Array([Vector2(-24, 8), Vector2(24, 8), Vector2(24, 15), Vector2(-24, 15)])
	_head.add_child(lens)
	_head_light = PointLight2D.new()
	_head_light.name = "HeadLight"
	_head_light.position = source
	_head_light.texture = LIGHT_TEX
	_head_light.color = Color(0.85, 0.92, 1.0)
	_head_light.energy = 0.8
	_head_light.texture_scale = 0.6
	add_child(_head_light)
