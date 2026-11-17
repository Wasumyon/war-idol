class_name CatwalkGuard
extends Node2D
## Chamber 4: a guard pacing a catwalk overhead, lantern angled down, so a pool
## of light slides along the floor ahead of him. The pool is a light_source:
## it holds the floor tubeworms back.
##   - FRONT fringe (the side he faces) burns orange-red; the BACK fringe is
##     dim and cool, so you can read his facing from the floor. Both are safe.
##   - The CORE is where he's looking: stand in it (not hidden) and he fires.
##   - Your LAMP on his facing side: he stops, "?", and his beam slides toward
##     your lamp (lamp_warn_time). Switch it off and he loses you. Keep it on
##     and "!", he shouts, and fires.
## At each end he waits, turns, and the pool swings across under him
## (swing_time); the core remains dangerous during the swing.
##
## Node origin = the guard's feet on the catwalk. floor_y = world y of the floor.

signal spotted_player
signal caught_player

const GUARD_ANIMATION = preload("res://minigames/tunnel/scripts/guard_animation.gd")
const LIGHT_TEX: Texture2D = preload("res://minigames/tunnel/art/light_radial.tres")

@export_group("Patrol")
@export var patrol_left: float = 350.0
@export var patrol_right: float = 2650.0
@export var walk_speed: float = 120.0
@export var wait_time: float = 1.4
## 1 = starts walking right, -1 = left.
@export var start_facing: int = 1

@export_group("Light")
## World y of the floor his pool lands on.
@export var floor_y: float = 0.0
## How far ahead of his feet the pool's centre sits.
@export var pool_lead: float = 130.0
## Half-width of the whole pool (fringe + core). The fringe keeps worms down.
@export var pool_half_width: float = 200.0
## Half-width of the bright core he's looking at.
@export var core_half_width: float = 70.0
## Seconds for the pool to swing across when he turns.
@export var swing_time: float = 1.1
## Lantern position relative to his feet, facing right.
@export var lantern_offset: Vector2 = Vector2(12, -50)
## His light never reaches past these world-xs (pillars / bulkheads cast the
## shadow): the pool, beam and floor light are cut off here, so the ground
## by a pillar stays fully dark.
@export var light_min_x: float = -100000.0
@export var light_max_x: float = 100000.0
## Render layers his lights touch: 1 (floor, worms, player), not 2 (pillars).
@export_flags_2d_render var light_cull_mask: int = 1

@export_group("Catch")
## Seconds in the core before he fires.
@export var catch_time: float = 0.5
## Your lamp is seen this far away (horizontally) when he's facing you.
@export var lamp_sight_range: float = 900.0
## The "?" stage: seconds your lamp can stay on in his view before he fires.
@export var lamp_warn_time: float = 0.8
## How fast his beam slides toward your lamp while he's suspicious.
@export var lamp_slide_speed: float = 320.0
## Furthest his beam reaches toward your lamp (from its normal spot).
@export var lamp_slide_max: float = 420.0
## After he loses your lamp, the core can't catch for this long (fair escape).
@export var lost_grace: float = 1.0
## Keep detection active while the pool swings across on a turn.
@export var catch_during_turn: bool = true
## He can only see the player between these world-xs (bulkheads at the ends
## of his catwalk block his view). Core and lamp both.
@export var sight_min_x: float = -100000.0
@export var sight_max_x: float = 100000.0

@export_group("Shot")
## Shouted (one at random) before he fires.
@export var shot_lines: PackedStringArray = PackedStringArray(["There he is! Fire!", "I see him! Fire!"])
## Seconds between the shout and the shot.
@export var shout_time: float = 1.5
## Seconds between the shot and the fade.
@export var after_shot: float = 0.25

enum State { WALK, WAIT, TURN, SHOOT }

const FRONT_BEAM: Color = Color(1.0, 0.5, 0.28, 0.13)
const BACK_BEAM: Color = Color(0.85, 0.75, 0.6, 0.05)
const FRONT_POOL: Color = Color(1.0, 0.45, 0.25, 0.22)
const BACK_POOL: Color = Color(0.9, 0.8, 0.65, 0.09)
const CORE_COL: Color = Color(1.0, 0.92, 0.65, 0.24)
const RED_COL: Color = Color(1.0, 0.3, 0.2, 0.32)

var state: State = State.WALK
var facing: int = 1
## Pool centre relative to his feet (x) = his normal aim + any slide toward a lamp.
var lead_x: float = 0.0
var pool_x: float = 0.0
## His normal aim (+lead ahead; swings on a turn).
var _aim: float = 0.0
## Extra offset while he looks toward your lamp.
var _slide: float = 0.0
var _wait_timer: float = 0.0
var _catch: float = 0.0
## Seconds your lamp has been seen (the "?" stage).
var _susp: float = 0.0
var _grace: float = 0.0
var _seen: bool = false
var _walk_phase: float = 0.0
var _swing_from: float = 0.0
var _swing_t: float = 0.0
var _shoot_t: float = 0.0
var _fired: bool = false
var _player: Player

var _visual: Node2D
var _sprite: GUARD_ANIMATION
var _front_beam: Polygon2D
var _back_beam: Polygon2D
var _core_beam: Polygon2D
var _front_pool: Polygon2D
var _back_pool: Polygon2D
var _core_pool: Polygon2D
var _floor_light: PointLight2D
var _lantern_light: PointLight2D
var _area: Area2D
var _area_shape: CollisionShape2D
var _alert_label: Label
var _speech: GlitchText
var _caught_with_lamp: bool = false


func _ready() -> void:
	var footsteps = preload("res://minigames/tunnel/scripts/footsteps.gd").new()
	footsteps.heavy = true
	footsteps.surface_override = "metal"
	add_child(footsteps)
	add_to_group("guard")
	facing = 1 if start_facing >= 0 else -1
	_aim = pool_lead * facing
	lead_x = _aim
	_build()
	_update_pool()
	_update_visual()


## Snap him to a spot facing a way (tests, scripted moments).
func place(x: float, dir: int) -> void:
	global_position.x = x
	facing = 1 if dir >= 0 else -1
	_visual.scale.x = float(facing)
	_aim = pool_lead * facing
	_slide = 0.0
	lead_x = _aim
	state = State.WALK
	_catch = 0.0
	_susp = 0.0
	_grace = 0.0
	_update_pool()


## True if the player stands in the bright core (and isn't hidden).
func player_in_core() -> bool:
	if _player == null or _player.is_dead or _player.is_hidden or not _in_view():
		return false
	if state == State.TURN and not catch_during_turn:
		return false
	var x: float = _player.global_position.x
	return x >= light_min_x and x <= light_max_x and absf(x - pool_x) <= core_half_width


## True if the player's lamp is on where he's looking (his facing side).
func sees_lamp() -> bool:
	if _player == null or _player.is_dead or not _player.is_torch_on or not _in_view():
		return false
	if not _player.lamp_seen_from(global_position):
		return false  # his beam points away and he's too far for the spill
	var dx: float = _player.global_position.x - global_position.x
	return dx * float(facing) > -40.0 and absf(dx) <= lamp_sight_range


## World-x span his light actually covers on the floor (after the clip).
func lit_span() -> Vector2:
	return Vector2(maxf(pool_x - pool_half_width, light_min_x), minf(pool_x + pool_half_width, light_max_x))


func is_suspicious() -> bool:
	return _susp > 0.0


func _in_view() -> bool:
	var x: float = _player.global_position.x
	return x >= sight_min_x and x <= sight_max_x


func catch_fraction() -> float:
	if state == State.SHOOT:
		return 1.0
	return clampf(maxf(_catch, _susp / lamp_warn_time), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player

	if state == State.SHOOT:
		_process_shoot(delta)
		_update_pool()
		_update_visual()
		return

	# Your lamp in his view: the "?" stage. He freezes and looks.
	var lamp_seen: bool = sees_lamp()
	if lamp_seen:
		if _susp <= 0.0:
			spotted_player.emit()
		_susp += delta
		_player.lamp_alarm(0.15)
		if _susp >= lamp_warn_time:
			_start_shoot(true)
			return
	elif _susp > 0.0:
		_susp = maxf(_susp - delta * 1.2, 0.0)
		if _susp <= 0.0:
			_grace = lost_grace
	_grace = maxf(_grace - delta, 0.0)
	var frozen: bool = _susp > 0.0

	if not frozen:
		match state:
			State.WALK:
				var target: float = patrol_right if facing > 0 else patrol_left
				global_position.x = move_toward(global_position.x, target, walk_speed * delta)
				_walk_phase += delta * 7.0
				if is_equal_approx(global_position.x, target):
					state = State.WAIT
					_wait_timer = wait_time
			State.WAIT:
				_settle_walk(delta)
				_wait_timer -= delta
				if _wait_timer <= 0.0:
					facing = -facing
					_visual.scale.x = float(facing)
					_swing_from = _aim
					_swing_t = 0.0
					state = State.TURN
			State.TURN:
				_settle_walk(delta)
				_swing_t = minf(_swing_t + delta / swing_time, 1.0)
				var e: float = 0.5 - 0.5 * cos(_swing_t * PI)
				_aim = lerpf(_swing_from, pool_lead * facing, e)
				if _swing_t >= 1.0:
					state = State.WALK
	else:
		_settle_walk(delta)

	# His beam slides toward your lamp while he's suspicious, then back.
	var slide_target: float = 0.0
	if lamp_seen:
		var want: float = _player.global_position.x - (global_position.x + _aim)
		slide_target = clampf(want, -lamp_slide_max, lamp_slide_max)
	elif frozen:
		slide_target = _slide
	_slide = move_toward(_slide, slide_target, lamp_slide_speed * delta)
	lead_x = _aim + _slide
	_update_pool()

	# The core: only when he isn't busy with your lamp, and not just after.
	if not frozen and _grace <= 0.0 and player_in_core():
		if _catch <= 0.0 and not _seen:
			spotted_player.emit()
		_seen = true
		_catch += delta / catch_time
		if _catch >= 1.0:
			_start_shoot()
			return
	else:
		_seen = false
		_catch = maxf(_catch - delta * 1.5, 0.0)

	_update_visual()


func _start_shoot(lamp_seen: bool = false) -> void:
	caught_player.emit()
	if TunnelManager.i.god_mode:
		_catch = 0.0
		_susp = 0.0
		return
	state = State.SHOOT
	_caught_with_lamp = lamp_seen
	_shoot_t = 0.0
	_fired = false
	var line: String = shot_lines[randi() % shot_lines.size()] if shot_lines.size() > 0 else ""
	if _player:
		_player.freeze()
	if line != "":
		_speech.say(line, 2.5)
		TunnelManager.i.set_death_line(line)


func _process_shoot(delta: float) -> void:
	_settle_walk(delta)
	_shoot_t += delta
	# Keep the light on him.
	if _player:
		_slide = move_toward(_slide, _player.global_position.x - (global_position.x + _aim), lamp_slide_speed * 2.0 * delta)
		lead_x = _aim + _slide
	if not _fired and _shoot_t >= shout_time:
		_fired = true
		if _player and not _player.is_dead:
			GunshotFX.fire(TunnelManager.i.chamber, global_position + _lantern_local() + Vector2(10 * facing, -6),
					_player.global_position + Vector2(0, -60))
			_player.hit_flash()
	if _fired and _shoot_t >= shout_time + after_shot:
		if _player and not _player.is_dead:
			var hint: String = TunnelManager.GUARD_LAMP_HINT if _caught_with_lamp else TunnelManager.GUARD_HINT
			_player.kill(self, hint)


func _settle_walk(delta: float) -> void:
	_walk_phase = lerpf(_walk_phase, roundf(_walk_phase / PI) * PI, delta * 8.0)


func _lantern_local() -> Vector2:
	return Vector2(lantern_offset.x * _light_facing(), lantern_offset.y)


## The lantern and fringe follow the continuous swing, not the sprite's flip.
func _light_facing() -> float:
	return clampf(_aim / maxf(pool_lead, 1.0), -1.0, 1.0)


func _update_pool() -> void:
	pool_x = global_position.x + lead_x
	var fy: float = floor_y - global_position.y  # floor, in local space
	var span: Vector2 = lit_span()
	_area.position = Vector2((span.x + span.y) * 0.5 - global_position.x, fy - 30.0)
	_area_shape.disabled = span.y <= span.x
	(_area_shape.shape as RectangleShape2D).size = Vector2(maxf(span.y - span.x, 1.0), 60.0)


func _update_visual() -> void:
	var moving: bool = state == State.WALK and _susp <= 0.0
	_sprite.animate(get_physics_process_delta_time(), moving, false)
	var fy: float = floor_y - global_position.y
	var lan: Vector2 = _lantern_local()
	var gx: float = global_position.x
	var c: float = lead_x
	var f: float = _light_facing()
	var fw: float = pool_half_width
	var cw: float = core_half_width
	# The lit span on the floor, clipped at the shadow edges (local x).
	var span: Vector2 = lit_span()
	var l: float = span.x - gx
	var r: float = span.y - gx
	var lit: bool = r > l + 2.0
	var cc: float = clampf(c, l, r)
	# Fixed right/left halves; their warmth blends as the lantern turns.
	var fa: float = cc
	var fb: float = r
	var ba: float = l
	var bb: float = cc
	var cl: float = maxf(c - cw, l)
	var cr: float = minf(c + cw, r)
	for poly: Polygon2D in [_front_beam, _back_beam, _core_beam, _front_pool, _back_pool, _core_pool]:
		poly.visible = lit
	_front_beam.polygon = PackedVector2Array([lan + Vector2(0, 4), lan + Vector2(8, 4), Vector2(fb, fy), Vector2(fa, fy)])
	_back_beam.polygon = PackedVector2Array([lan + Vector2(-8, 4), lan + Vector2(0, 4), Vector2(bb, fy), Vector2(ba, fy)])
	_core_beam.visible = lit and cr > cl
	_core_beam.polygon = PackedVector2Array([lan + Vector2(-4, 4), lan + Vector2(4, 4), Vector2(cr, fy), Vector2(cl, fy)])
	_front_pool.polygon = _span_ellipse(fa, fb, c, fw, fy, 12.0)
	_back_pool.polygon = _span_ellipse(ba, bb, c, fw, fy, 12.0)
	_core_pool.visible = lit and cr > cl
	_core_pool.polygon = _span_ellipse(cl, cr, c, cw, fy, 9.0)
	# Floor light sized to the lit span only, so it doesn't spill past the clip.
	_floor_light.enabled = lit
	_floor_light.position = Vector2((l + r) * 0.5, fy - 24.0)
	_floor_light.scale = Vector2(maxf(r - l, 1.0) / 512.0, 0.6)
	_lantern_light.position = lan

	var t: float = catch_fraction()
	_core_beam.color = CORE_COL.lerp(RED_COL, t)
	_core_pool.color = Color(1.0, 0.92, 0.7, 0.35).lerp(Color(1.0, 0.35, 0.25, 0.45), t)
	var warmth: float = (f + 1.0) * 0.5
	var warm_pool: Color = FRONT_POOL.lerp(Color(1.0, 0.3, 0.2, 0.3), t)
	var warm_beam: Color = FRONT_BEAM.lerp(Color(1.0, 0.3, 0.2, 0.2), t)
	_front_pool.color = BACK_POOL.lerp(warm_pool, warmth)
	_back_pool.color = warm_pool.lerp(BACK_POOL, warmth)
	_front_beam.color = BACK_BEAM.lerp(warm_beam, warmth)
	_back_beam.color = warm_beam.lerp(BACK_BEAM, warmth)
	var alarmed: bool = state == State.SHOOT or _catch > 0.5
	_alert_label.visible = alarmed or _susp > 0.0 or _catch > 0.0
	_alert_label.text = "!" if alarmed else "?"
	_alert_label.modulate = Color(1, 0.85, 0.3).lerp(Color(1, 0.2, 0.15), t)
	_alert_label.scale = Vector2.ONE * (0.8 + 0.5 * t)


## The piece of a flat floor ellipse (centre cx, half-width hw) between x0 and x1.
func _span_ellipse(x0: float, x1: float, cx: float, hw: float, cy: float, hh: float) -> PackedVector2Array:
	var top: PackedVector2Array = PackedVector2Array()
	var bot: PackedVector2Array = PackedVector2Array()
	if x1 <= x0:
		return top
	var n: int = 12
	for i: int in n + 1:
		var x: float = lerpf(x0, x1, float(i) / float(n))
		var u: float = (x - cx) / hw
		var h: float = hh * sqrt(maxf(1.0 - u * u, 0.0))
		top.append(Vector2(x, cy - h))
		bot.append(Vector2(x, cy + h * 0.6))
	bot.reverse()
	return top + bot


func _build() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	_visual.scale.x = float(facing)
	add_child(_visual)
	_sprite = GUARD_ANIMATION.new()
	_sprite.name = "Sprite"
	_visual.add_child(_sprite)

	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_back_beam = _poly("BackBeam", add, BACK_BEAM, -2)
	_front_beam = _poly("FrontBeam", add, FRONT_BEAM, -2)
	_core_beam = _poly("CoreBeam", add, CORE_COL, -2)
	_back_pool = _poly("BackPool", add, BACK_POOL, 3)
	_front_pool = _poly("FrontPool", add, FRONT_POOL, 3)
	_core_pool = _poly("CorePool", add, CORE_COL, 3)

	_floor_light = PointLight2D.new()
	_floor_light.name = "PoolLight"
	_floor_light.texture = LIGHT_TEX
	_floor_light.color = Color(1.0, 0.75, 0.5)
	_floor_light.energy = 1.2
	_floor_light.texture_scale = 1.0
	_floor_light.range_item_cull_mask = light_cull_mask
	add_child(_floor_light)
	_lantern_light = PointLight2D.new()
	_lantern_light.name = "LanternLight"
	_lantern_light.texture = LIGHT_TEX
	_lantern_light.color = Color(1.0, 0.75, 0.45)
	_lantern_light.energy = 0.8
	_lantern_light.texture_scale = 0.6
	_lantern_light.range_item_cull_mask = light_cull_mask
	add_child(_lantern_light)

	# The pool on the floor as a light area (layer 3): retracts tubeworms.
	_area = Area2D.new()
	_area.name = "PoolArea"
	_area.collision_layer = 0b100
	_area.collision_mask = 0
	_area.monitoring = false
	_area.monitorable = true
	_area.add_to_group("light_source")
	_area.add_to_group("guard_light")
	add_child(_area)
	_area_shape = CollisionShape2D.new()
	_area_shape.name = "Shape"
	_area_shape.shape = RectangleShape2D.new()
	_area.add_child(_area_shape)

	_alert_label = Label.new()
	_alert_label.name = "Alert"
	_alert_label.text = "?"
	_alert_label.add_theme_font_size_override("font_size", 40)
	_alert_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_alert_label.add_theme_constant_override("outline_size", 6)
	_alert_label.position = Vector2(-8, -175)
	_alert_label.pivot_offset = Vector2(8, 24)
	_alert_label.z_index = 5
	_alert_label.visible = false
	var lmat: CanvasItemMaterial = CanvasItemMaterial.new()
	lmat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_alert_label.material = lmat
	add_child(_alert_label)

	_speech = GlitchText.make_world_speech(self, Vector2(0, -195))


func _poly(n: String, mat: Material, c: Color, z: int) -> Polygon2D:
	var p: Polygon2D = Polygon2D.new()
	p.name = n
	p.material = mat
	p.color = c
	p.z_index = z
	add_child(p)
	return p
