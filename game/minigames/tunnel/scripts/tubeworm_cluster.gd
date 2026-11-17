class_name TubewormCluster
extends Area2D
## A cluster of hydrothermal-vent tubeworms growing from rubble.
## Thick bone-white stalks with crimson feathery plumes. Light makes them retract;
## darkness lets them grow back. Drawn procedurally until real art exists.
##
## Node origin = the base of the cluster (on the floor, or on the ceiling if from_ceiling).

signal retracted
signal regrown

@export var width: float = 220.0
@export var max_height: float = 360.0
@export var stalk_count: int = 16
@export var from_ceiling: bool = false
## Touching them while grown costs a heart, even from outside.
@export var deadly: bool = false
## Standing inside the cluster when it grows back costs a heart.
@export var kill_if_caught: bool = true
## How far grown (0-1) the worms must be before they catch someone standing inside.
@export var catch_growth: float = 0.6
## When grown, a solid collider stops the player walking through.
@export var blocks_path: bool = true
@export var retract_time: float = 0.55
@export var regrow_delay: float = 0.9
@export var regrow_time: float = 1.4
@export var random_seed: int = 7
## If > 0, a light only counts when its source (the lamp) is within this many px
## (horizontally) of the cluster: the beam has to be pushed right up to them.
## Used for layered walls, so each row parts in turn instead of all at once.
@export var light_reach: float = 0.0

## 1.0 = fully grown, 0.0 = fully withdrawn into the rubble.
var growth: float = 1.0
var is_lit: bool = false

var _stalks: Array[Dictionary] = []
var _dark_timer: float = 0.0
var _tween: Tween
var _blocker_shape: CollisionShape2D
var _entry_side: float = 0.0
## Visual-only controls: 0 redraw_fps restores the original every-tick drawing.
@export var redraw_fps: float = 30.0
@export_range(3, 12) var curve_segments: int = 8
@export_range(3, 12) var plume_feathers: int = 7
@export var cull_offscreen_drawing: bool = true
## Sends the whole cluster to the GPU as one mesh (one draw call) instead of
## ~23 separate draw calls per stalk. Off restores the original drawing.
@export var batched_drawing: bool = true
var _mv: PackedVector2Array = PackedVector2Array()
var _mc: PackedColorArray = PackedColorArray()
var _mi: PackedInt32Array = PackedInt32Array()
var _circle: PackedVector2Array = PackedVector2Array()
var _draw_timer: float = 0.0
var _visibility: VisibleOnScreenNotifier2D
var _time: float = 0.0

const BONE: Color = Color(0.90, 0.87, 0.80)
const BONE_EDGE: Color = Color(0.48, 0.45, 0.42)
const PLUME: Color = Color(0.72, 0.07, 0.10)
const RUBBLE: Color = Color(0.27, 0.26, 0.25)
const DEATH_HINT: String = "They come back up in the dark.\nI need to keep them in the light\nuntil I’m through."


func _ready() -> void:
	# Detect light areas (layer 3) and the player (layer 2).
	collision_layer = 0
	collision_mask = 0b110
	monitoring = true
	monitorable = false
	_build_shapes()
	_build_stalks()
	for j: int in 10:
		_circle.append(Vector2.from_angle(TAU * float(j) / 10.0))
	_visibility = VisibleOnScreenNotifier2D.new()
	# Include stalk sway, crowns and rubble, including rotated shaft clusters.
	var top: float = -30.0 if from_ceiling else -max_height - 40.0
	_visibility.rect = Rect2(-width * 0.6 - 40.0, top, width * 1.2 + 80.0, max_height + 80.0)
	add_child(_visibility)


func _physics_process(delta: float) -> void:
	_time += delta
	var lit_now: bool = _has_light()
	if lit_now:
		_dark_timer = 0.0
		if not is_lit:
			is_lit = true
			_retract()
	elif is_lit:
		# Light just left: wait a beat, then creep back out.
		_dark_timer += delta
		if _dark_timer >= regrow_delay:
			is_lit = false
			_regrow()

	_update_blocker()
	if deadly or kill_if_caught:
		var player_in_reach: bool = false
		for body: Node2D in get_overlapping_bodies():
			if not body is Player:
				continue
			player_in_reach = true
			if _entry_side == 0.0 or not _is_inside_core(body):
				_entry_side = -1.0 if body.global_position.x <= global_position.x else 1.0
			if (deadly and growth > 0.5) or (kill_if_caught and not is_lit
					and growth > catch_growth and _is_inside_core(body)):
				_knock_clear(body as Player)
		if not player_in_reach:
			_entry_side = 0.0
	# Physics/light sensing above remains at full rate, even off screen.
	_draw_timer += delta
	if (not cull_offscreen_drawing or _visibility.is_on_screen()) \
			and (redraw_fps <= 0.0 or _draw_timer >= 1.0 / redraw_fps):
		_draw_timer = 0.0
		queue_redraw()


func _knock_clear(player: Player) -> void:
	var reach: float = width * (0.5 if deadly else 0.3) + 20.0
	var landing_x: float = global_position.x + _entry_side * reach
	# Walk the landing past adjacent rows if the first gap is too narrow.
	var rows: Array[Node] = get_parent().get_children()
	for _pass: int in rows.size():
		var clear: bool = true
		for node: Node in rows:
			var row := node as TubewormCluster
			if row == null or row == self or row.from_ceiling != from_ceiling:
				continue
			var clearance: float = row.width * (0.5 if row.deadly else 0.3) + 20.0
			if absf(row.global_position.x - landing_x) < clearance:
				landing_x = row.global_position.x + _entry_side * clearance
				clear = false
		if clear:
			break
	player.take_worm_hit(self, DEATH_HINT, landing_x)


## True if the body stands in the middle of the cluster, where the wall closes.
## Brushing the outer edge of grown worms is safe.
func _is_inside_core(body: Node2D) -> bool:
	return absf(body.global_position.x - global_position.x) < width * 0.3


func _has_light() -> bool:
	for area: Area2D in get_overlapping_areas():
		if area.is_in_group("light_source") and area.monitorable:
			if light_reach > 0.0 and absf(area.global_position.x - global_position.x) > light_reach:
				continue
			return true
	return false


func _retract() -> void:
	_dark_timer = 0.0
	_animate_growth(0.0, retract_time)
	retracted.emit()


func _regrow() -> void:
	_animate_growth(1.0, regrow_time)
	regrown.emit()


func _animate_growth(target: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "growth", target, duration * absf(growth - target))


## The wall is solid while the worms are mostly out. It never closes on top of
## the player (non-deadly clusters), so regrowing can't trap him inside.
func _update_blocker() -> void:
	if not blocks_path or _blocker_shape == null:
		return
	var should_block: bool = growth > 0.4
	if should_block and _blocker_shape.disabled:
		for body: Node2D in get_overlapping_bodies():
			if body is Player:
				should_block = false
	if _blocker_shape.disabled == should_block:
		_blocker_shape.set_deferred("disabled", not should_block)


func _build_shapes() -> void:
	var dir: float = 1.0 if from_ceiling else -1.0
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, max_height)
	var detector: CollisionShape2D = CollisionShape2D.new()
	detector.shape = rect
	detector.position = Vector2(0.0, dir * max_height * 0.5)
	add_child(detector)

	if blocks_path:
		var body: StaticBody2D = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		var wall: RectangleShape2D = RectangleShape2D.new()
		wall.size = Vector2(width * 0.6, max_height)
		_blocker_shape = CollisionShape2D.new()
		_blocker_shape.shape = wall
		_blocker_shape.position = detector.position
		body.add_child(_blocker_shape)


func _build_stalks() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = random_seed
	_stalks.clear()
	for i: int in stalk_count:
		_stalks.append({
			"x": rng.randf_range(-width * 0.45, width * 0.45),
			"height": rng.randf_range(0.5, 1.0) * max_height,
			"thickness": rng.randf_range(9.0, 17.0),
			"phase": rng.randf_range(0.0, TAU),
			"sway": rng.randf_range(6.0, 16.0),
			"lean": rng.randf_range(-0.12, 0.12),
			"plume": rng.randf_range(12.0, 20.0),
		})
	# Draw thin ones last so they sit in front.
	_stalks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["thickness"] > b["thickness"])


func _draw() -> void:
	if not batched_drawing:
		_draw_unbatched()
		return
	# Same picture as _draw_unbatched(), built as a single triangle mesh.
	_mv.clear()
	_mc.clear()
	_mi.clear()
	var dir: float = 1.0 if from_ceiling else -1.0
	var squirm: float = 1.0 - growth  # writhe harder while moving
	var segments: int = curve_segments
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(segments + 1)
	for s: Dictionary in _stalks:
		var h: float = (s["height"] as float) * growth
		if h < 2.0:
			continue
		var sx: float = s["x"] as float
		var lean: float = s["lean"] as float
		var sway: float = s["sway"] as float
		var phase: float = s["phase"] as float
		var rate: float = _time * (1.3 + squirm * 4.0) + phase
		for k: int in segments + 1:
			var t: float = float(k) / float(segments)
			points[k] = Vector2(sx + lean * h * t + sin(rate + t * 2.2) * sway * t * t, dir * h * t)
		var thick: float = s["thickness"] as float
		_add_strip(points, thick * 0.5 + 1.5, BONE_EDGE, true)
		_add_strip(points, thick * 0.5, BONE, false)
		_add_disc(points[0], thick * 0.5 + 1.5, BONE_EDGE)
		_add_plume(points[segments], points[segments] - points[segments - 1], s, thick)

	# Rubble mound the worms withdraw into.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = random_seed + 99
	for i: int in 9:
		var cx: float = rng.randf_range(-width * 0.55, width * 0.55)
		var r: float = rng.randf_range(10.0, 24.0)
		var base: int = _mv.size()
		for j: int in 5:
			var a: float = TAU * float(j) / 5.0 + rng.randf_range(-0.3, 0.3)
			_mv.append(Vector2(cx + cos(a) * r, sin(a) * r * 0.55 + dir * r * 0.2))
		var shade: Color = RUBBLE.darkened(rng.randf_range(0.0, 0.35))
		for j: int in 5:
			_mc.append(shade)
		for j: int in 3:
			_mi.append(base)
			_mi.append(base + j + 1)
			_mi.append(base + j + 2)
	if _mi.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _mi, _mv, _mc)


## A thick ribbon along the points. soft adds a 1 px fade-out rim so the
## silhouette stays smooth without antialiased draw calls.
func _add_strip(points: PackedVector2Array, half: float, color: Color, soft: bool) -> void:
	var n: int = points.size()
	var per: int = 4 if soft else 2
	var base: int = _mv.size()
	var fade: Color = Color(color, 0.0)
	for k: int in n:
		var side: Vector2 = (points[mini(k + 1, n - 1)] - points[maxi(k - 1, 0)]).orthogonal().normalized()
		var p: Vector2 = points[k]
		if soft:
			_mv.append(p + side * (half + 1.0))
			_mc.append(fade)
		_mv.append(p + side * half)
		_mc.append(color)
		_mv.append(p - side * half)
		_mc.append(color)
		if soft:
			_mv.append(p - side * (half + 1.0))
			_mc.append(fade)
	for k: int in n - 1:
		var o: int = base + k * per
		for j: int in per - 1:
			_add_quad(o + j, o + j + 1, o + per + j, o + per + j + 1)


func _add_quad(a: int, b: int, c: int, d: int) -> void:
	_mi.append(a)
	_mi.append(b)
	_mi.append(c)
	_mi.append(b)
	_mi.append(d)
	_mi.append(c)


func _add_disc(center: Vector2, radius: float, color: Color) -> void:
	var base: int = _mv.size()
	var n: int = _circle.size()
	_mv.append(center)
	_mc.append(color)
	for j: int in n:
		_mv.append(center + _circle[j] * radius)
		_mc.append(color)
	for j: int in n:
		_mi.append(base)
		_mi.append(base + 1 + j)
		_mi.append(base + 1 + (j + 1) % n)


func _add_plume(tip: Vector2, heading: Vector2, s: Dictionary, thick: float) -> void:
	# Feathery crimson crown that folds shut as the worm retracts.
	var forward: Vector2 = heading.normalized()
	var spread: float = 0.35 + 0.75 * growth
	var length: float = (s["plume"] as float) * (0.4 + 0.6 * growth)
	var count: int = plume_feathers
	var bright: Color = PLUME.lightened(0.15)
	var phase: float = _time * 2.0 + (s["phase"] as float)
	for i: int in count:
		var t: float = (float(i) / float(count - 1)) * 2.0 - 1.0
		var along: Vector2 = forward.rotated(t * spread + sin(phase + t) * 0.08)
		var across: Vector2 = along.orthogonal()
		var end: Vector2 = tip + along * length
		var base: int = _mv.size()
		_mv.append(tip + across * 1.1)
		_mv.append(tip - across * 1.1)
		_mv.append(end + across * 1.1)
		_mv.append(end - across * 1.1)
		# Tip bead: a 2 px diamond reads the same as a circle at this size.
		_mv.append(end + along * 1.9)
		_mv.append(end + across * 1.9)
		_mv.append(end - along * 1.9)
		_mv.append(end - across * 1.9)
		for j: int in 4:
			_mc.append(PLUME)
		for j: int in 4:
			_mc.append(bright)
		_add_quad(base, base + 1, base + 2, base + 3)
		_add_quad(base + 4, base + 5, base + 7, base + 6)
	_add_disc(tip, thick * 0.45, PLUME.darkened(0.25))


func _draw_unbatched() -> void:
	var dir: float = 1.0 if from_ceiling else -1.0
	var squirm: float = 1.0 - growth  # writhe harder while moving
	for s: Dictionary in _stalks:
		var h: float = (s["height"] as float) * growth
		if h < 2.0:
			continue
		var points: PackedVector2Array = PackedVector2Array()
		var segments: int = curve_segments
		for k: int in segments + 1:
			var t: float = float(k) / float(segments)
			var wobble: float = sin(_time * (1.3 + squirm * 4.0) + (s["phase"] as float) + t * 2.2)
			var x: float = (s["x"] as float) + (s["lean"] as float) * h * t \
				+ wobble * (s["sway"] as float) * t * t
			points.append(Vector2(x, dir * h * t))
		var thick: float = s["thickness"] as float
		draw_polyline(points, BONE_EDGE, thick + 3.0, true)
		draw_polyline(points, BONE, thick, true)
		draw_circle(points[0], thick * 0.5 + 1.5, BONE_EDGE)
		_draw_plume(points[segments], points[segments] - points[segments - 1], s, thick)

	# Rubble mound the worms withdraw into.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = random_seed + 99
	for i: int in 9:
		var cx: float = rng.randf_range(-width * 0.55, width * 0.55)
		var r: float = rng.randf_range(10.0, 24.0)
		var rock: PackedVector2Array = PackedVector2Array()
		for j: int in 5:
			var a: float = TAU * float(j) / 5.0 + rng.randf_range(-0.3, 0.3)
			rock.append(Vector2(cx + cos(a) * r, sin(a) * r * 0.55 + dir * r * 0.2))
		draw_colored_polygon(rock, RUBBLE.darkened(rng.randf_range(0.0, 0.35)))


func _draw_plume(tip: Vector2, heading: Vector2, s: Dictionary, thick: float) -> void:
	# Feathery crimson crown that folds shut as the worm retracts.
	var forward: Vector2 = heading.normalized()
	var spread: float = 0.35 + 0.75 * growth
	var length: float = (s["plume"] as float) * (0.4 + 0.6 * growth)
	var count: int = plume_feathers
	for i: int in count:
		var t: float = (float(i) / float(count - 1)) * 2.0 - 1.0
		var angle: float = t * spread + sin(_time * 2.0 + (s["phase"] as float) + t) * 0.08
		var end: Vector2 = tip + forward.rotated(angle) * length
		draw_line(tip, end, PLUME, 2.2, true)
		draw_circle(end, 1.6, PLUME.lightened(0.15))
	draw_circle(tip, thick * 0.45, PLUME.darkened(0.25))
