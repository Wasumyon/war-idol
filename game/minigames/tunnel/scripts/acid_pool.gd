class_name AcidPool
extends Area2D
## Acid with isolated tube worms and an optional dense bed.
## The isolated stalks give you time to walk past in the dark. The lantern delays
## the warning in either bed.

signal warning_started
signal struck

## Half the width of the acid surface (where it meets the slopes).
@export var half_width: float = 152.0
## Half the width of the flat pool bottom.
@export var bottom_half_width: float = 130.0
## Extra length on the left bank, applied to the surface and the bottom.
@export var entry_extension: float = 0.0
## Depth from the surface to the pool bottom.
@export var depth: float = 30.0
@export var has_dense_bed: bool = true
## Local x where the worm bed starts; only past this can they get him.
@export var danger_start: float = -40.0
## Center of the pair, and the half-width of each isolated hazard's reach.
## Zero reach disables the isolated stalks.
@export var entry_stalk_x: float = 0.0
@export var entry_stalk_reach: float = 0.0
## Additional single stalks in the shallows, at local x positions.
@export var single_stalks: PackedFloat32Array
## Dry platform inside the pool, if the room has one (local x).
@export var dry_ledge_x: float = NAN
@export var entry_linger_time: float = 0.6
@export var entry_light_hold_time: float = 0.7
@export var entry_warn_time: float = 1.0
## How far inside the surface edge his feet must be before the worms can reach him.
@export var reach_margin: float = 6.0
## Traction while reversing in the acid. Walking speed and braking stay the same.
@export_range(0.1, 1.0) var reverse_grip: float = 0.55
## Seconds of warning bubbling before the worms burst up.
@export var warn_time: float = 0.5
## Seconds of lit wading the lamp buys before the worms push up anyway.
@export var light_hold_time: float = 1.4
## Seconds between the burst and the kill (so you see them get him).
@export var strike_time: float = 0.3
@export var glow: PointLight2D
## A guard who shares the isolated stalks' warning when wading within reach.
@export var guard: EnemyGuard

enum State { IDLE, WARN, STRIKE }
var state: State = State.IDLE
var lit_time: float = 0.0
var warn_t: float = 0.0
var strike_t: float = 0.0

var _player: Player
var _wading: bool = false
var _in_danger: bool = false
var _entry_time: float = 0.0
var _entry_lit_time: float = 0.0
var _guard_entry_time: float = 0.0
var _player_stalk: int = -1
var _guard_stalk: int = -1
var _warning_stalk: int = -1
var _entry_warning: bool = false
var _warning_for_player: bool = false
var _warning_mark: Label
var _time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _bubbles: Array[Dictionary] = []
var _pops: Array[Dictionary] = []
var _bubble_acc: float = 0.0
var _burst: Array[Dictionary] = []
var _strike_x: float = 0.0
var _step_t: float = 0.0
var _entered_from_left: bool = true
var _sizzle: AudioStreamPlayer2D
var _sfx: Dictionary = {}

const ACID: Color = Color(0.42, 0.66, 0.10, 0.9)
const ACID_DEEP: Color = Color(0.20, 0.36, 0.05, 0.95)
const ACID_FOAM: Color = Color(0.78, 0.95, 0.42, 1.0)
const BONE: Color = Color(0.90, 0.87, 0.80)
const BONE_EDGE: Color = Color(0.48, 0.45, 0.42)
const PLUME: Color = Color(0.72, 0.07, 0.10)
const STALK_SHADOW: Color = Color(0.16, 0.19, 0.13, 0.92)
const STALK_EDGE: Color = Color(0.44, 0.41, 0.28, 0.7)
const STALK_TIP: Color = Color(0.55, 0.26, 0.20)
const ENTRY_STALK_OFFSETS: Array[float] = [-13.0, 13.0]
const DEATH_HINT: String = "The light keeps the tube worms down…\nbut only for a second. I gotta save my\nbreath for the deep part."
const SHALLOW_DEATH_HINT: String = "Those worms boil up if I stand there too long.\nI can just keep walking."


func _ready() -> void:
	add_to_group("acid_pools")
	collision_layer = 0
	collision_mask = 0b10
	monitoring = true
	monitorable = false
	_rng.seed = 11
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(half_width * 2.0 + entry_extension + 40.0, 260.0)
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(-entry_extension * 0.5, -100.0)
	add_child(shape)

	_sizzle = AudioStreamPlayer2D.new()
	_sizzle.stream = load("res://minigames/tunnel/art/sfx/acid_sizzle.wav")
	_sizzle.volume_db = -16.0
	_sizzle.max_distance = 900.0
	_sizzle.autoplay = true
	_sizzle.finished.connect(_sizzle.play)
	add_child(_sizzle)
	for s: String in ["acid_squelch", "acid_bubbles", "acid_burst", "worm_strike"]:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.stream = load("res://minigames/tunnel/art/sfx/%s.wav" % s)
		add_child(p)
		_sfx[s] = p
	_warning_mark = Label.new()
	_warning_mark.text = "!"
	_warning_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_mark.add_theme_font_size_override("font_size", 30)
	_warning_mark.add_theme_color_override("font_color", Color("#ff645a"))
	_warning_mark.add_theme_color_override("font_outline_color", Color("#231211"))
	_warning_mark.add_theme_constant_override("outline_size", 5)
	_warning_mark.z_index = 4
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_warning_mark.material = unshaded
	_warning_mark.hide()
	add_child(_warning_mark)


func _physics_process(delta: float) -> void:
	_time += delta
	_find_player()
	var p: Player = _player
	var was_wading: bool = _wading
	_wading = p != null and not p.is_dead and not p.is_hidden and _feet_in_acid(p.global_position)
	if _wading and not was_wading:
		_entered_from_left = to_local(p.global_position).x < -entry_extension * 0.5
	_update_wading(p, delta)
	var px: float = to_local(p.global_position).x if _wading else 0.0
	_in_danger = has_dense_bed and _wading and px > danger_start
	var player_stalk: int = _stalk_in_reach(px, entry_stalk_reach) if _wading and not _in_danger else -1
	if player_stalk != _player_stalk:
		_entry_time = 0.0
		_entry_lit_time = 0.0
		_player_stalk = player_stalk
	var lamp_on: bool = p != null and p.is_torch_on
	if _player_stalk >= 0:
		_entry_time += delta
		if lamp_on and _entry_time >= entry_linger_time:
			_entry_lit_time += delta
	if not _in_danger:
		lit_time = 0.0
	elif lamp_on:
		lit_time += delta
	var can_hit: bool = p != null and p.can_take_worm_hit()
	var entry_threat: bool = can_hit and _player_stalk >= 0 and _entry_time >= entry_linger_time \
			and (not lamp_on or _entry_lit_time >= entry_light_hold_time)
	var deep_threat: bool = can_hit and _in_danger and (not lamp_on or lit_time >= light_hold_time)
	var guard_reach: float = entry_stalk_reach + EnemyGuard.BODY_HALF_WIDTH
	var guard_stalk: int = -1
	if is_instance_valid(guard) and guard.state != EnemyGuard.State.CAUGHT and _feet_in_acid(guard.global_position):
		guard_stalk = _stalk_in_reach(to_local(guard.global_position).x, guard_reach)
	if guard_stalk != _guard_stalk:
		_guard_entry_time = 0.0
		_guard_stalk = guard_stalk
	if _guard_stalk >= 0:
		_guard_entry_time += delta
	var guard_threat: bool = _guard_stalk >= 0 and _guard_entry_time >= entry_linger_time

	match state:
		State.IDLE:
			if deep_threat:
				_start_warning(-1, true)
			elif entry_threat or guard_threat:
				_start_warning(_player_stalk if entry_threat else _guard_stalk, entry_threat)
		State.WARN:
			if _entry_warning and entry_threat and _player_stalk != _warning_stalk:
				_start_warning(_player_stalk, true)
			warn_t += delta
			var player_threat: bool = entry_threat and _player_stalk == _warning_stalk if _entry_warning else deep_threat
			# The guard's warning never shortens the player's time to get clear.
			if player_threat and not _warning_for_player:
				warn_t = 0.0
			_warning_for_player = player_threat
			var threatened: bool = player_threat or (_entry_warning and guard_threat and _guard_stalk == _warning_stalk)
			if not threatened:
				state = State.IDLE
			elif warn_t >= _warning_duration():
				if player_threat:
					_strike(p)
				else:
					state = State.IDLE
					_guard_entry_time = 0.0
		State.STRIKE:
			strike_t += delta
			if strike_t >= strike_time and strike_t - delta < strike_time and p != null:
				p.take_worm_hit(self, DEATH_HINT if has_dense_bed else SHALLOW_DEATH_HINT, _landing_x())
				if not p.is_dead:
					p.controls_enabled = true
			if strike_t >= strike_time + 0.4:
				state = State.IDLE
				lit_time = 0.0
				_entry_time = 0.0
				_entry_lit_time = 0.0
				_burst.clear()

	if state == State.WARN and _entry_warning and _guard_stalk == _warning_stalk:
		guard.step_clear_of_stalks(to_global(Vector2(_stalk_x(_warning_stalk), 0.0)).x, guard_reach)
	_warning_mark.visible = state == State.WARN and _warning_for_player
	if _warning_mark.visible:
		_warning_mark.position = to_local(p.global_position) + Vector2(-8.0, -186.0)
	_update_bubbles(delta)
	if _sizzle:
		var target: float = -16.0
		if state == State.WARN:
			target = -6.0
		elif _wading:
			target = -11.0
		_sizzle.volume_db = move_toward(_sizzle.volume_db, target, 40.0 * delta)
	if glow:
		var g: float = 0.5 + 0.08 * sin(_time * 2.3)
		if state == State.WARN:
			g += 0.4 * warn_t / _warning_duration()
		elif state == State.STRIKE:
			g = 1.1
		glow.energy = g
	queue_redraw()


func _find_player() -> void:
	if is_instance_valid(_player):
		return
	_player = null
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			_player = body as Player
	if _player == null:
		var n: Node = get_tree().get_first_node_in_group("player")
		if n is Player:
			_player = n as Player


## The actor's feet are in the acid, past the shallow edge.
func _feet_in_acid(feet: Vector2) -> bool:
	var local: Vector2 = to_local(feet)
	return local.x > -half_width - entry_extension + reach_margin \
			and local.x < half_width - reach_margin and local.y > 2.0


func _landing_x() -> float:
	var left_bank: float = -half_width - entry_extension - 25.0
	var right_bank: float = half_width + 25.0
	var landing: float = left_bank if _entered_from_left else right_bank
	# Once on the exit slope, recover onto that bank.
	if _strike_x > bottom_half_width:
		landing = right_bank
	elif _strike_x < -bottom_half_width - entry_extension:
		landing = left_bank
	if not is_nan(dry_ledge_x) and (absf(dry_ledge_x - _strike_x) <= 80.0
			or (dry_ledge_x - _strike_x) * (landing - dry_ledge_x) > 0.0):
		landing = dry_ledge_x
	return to_global(Vector2(landing, 0.0)).x


func _stalk_in_reach(x: float, reach: float) -> int:
	if entry_stalk_reach <= 0.0:
		return -1
	var nearest: int = -1
	for i: int in range(single_stalks.size() + 1):
		var distance: float = absf(x - _stalk_x(i))
		if distance < reach:
			nearest = i
			reach = distance
	return nearest


func _stalk_x(index: int) -> float:
	return entry_stalk_x if index == 0 else single_stalks[index - 1]


func _update_wading(p: Player, delta: float) -> void:
	if p == null:
		return
	if _wading:
		p.acid_pool = self
		if absf(p.velocity.x) > 20.0:
			_step_t += delta
			if _step_t >= 0.42:
				_step_t = 0.0
				_play("acid_squelch", -8.0, _rng.randf_range(0.85, 1.15))
				_spawn_splash(to_local(p.global_position).x)
		else:
			_step_t = 0.3
	else:
		if p.acid_pool == self:
			p.acid_pool = null
		_step_t = 0.3


func _warning_duration() -> float:
	return entry_warn_time if _entry_warning else warn_time


func _start_warning(stalk: int, for_player: bool) -> void:
	state = State.WARN
	_warning_stalk = stalk
	_entry_warning = stalk >= 0
	_warning_for_player = for_player
	warn_t = 0.0
	_play("acid_bubbles", -4.0, 1.0)
	warning_started.emit()


func _strike(p: Player) -> void:
	state = State.STRIKE
	strike_t = 0.0
	_strike_x = to_local(p.global_position).x
	_burst.clear()
	var stalk_count: int = ENTRY_STALK_OFFSETS.size() if _entry_warning else 6
	if _warning_stalk > 0:
		stalk_count = 1
	for i: int in stalk_count:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var base_x: float = entry_stalk_x + ENTRY_STALK_OFFSETS[i] if _entry_warning \
				else _strike_x + side * _rng.randf_range(6.0, 44.0)
		if _warning_stalk > 0:
			base_x = _stalk_x(_warning_stalk)
			side = -1.0 if _strike_x >= base_x else 1.0
		var height_scale: float = 0.67 if _entry_warning else 1.0
		_burst.append({
			"x": base_x,
			"height": _rng.randf_range(120.0, 210.0) * height_scale,
			"thick": _rng.randf_range(9.0, 15.0),
			"lean": -side * _rng.randf_range(0.15, 0.4),  # curl in over him
			"phase": _rng.randf_range(0.0, TAU),
			"delay": _rng.randf_range(0.0, 0.06),
		})
	p.freeze()
	p.hit_flash()
	_play("acid_burst", 0.0, 1.0)
	_play("worm_strike", -3.0, 0.9)
	for i: int in 3:
		_spawn_splash(_strike_x + _rng.randf_range(-30.0, 30.0))
	struck.emit()


func _play(sfx: String, volume_db: float, pitch: float) -> void:
	var a: AudioStreamPlayer = _sfx.get(sfx)
	if a == null:
		return
	a.volume_db = volume_db
	a.pitch_scale = pitch
	a.play()


## Bubbles rise from the bottom and pop at the surface. A few drift up anywhere;
## lit wading stirs more around him as the worms strain; the warning boils.
func _update_bubbles(delta: float) -> void:
	var rate: float = 4.0
	var near_x: float = (danger_start + bottom_half_width) * 0.5
	var near_spread: float = (bottom_half_width - danger_start) * 0.5
	var left_limit: float = danger_start
	if not has_dense_bed:
		near_x = entry_stalk_x
		near_spread = entry_stalk_reach
		left_limit = entry_stalk_x - entry_stalk_reach
	if state == State.WARN and _entry_warning:
		near_x = _stalk_x(_warning_stalk)
		near_spread = entry_stalk_reach
		left_limit = near_x - entry_stalk_reach
		rate = 70.0
	elif _player != null and (_in_danger or state != State.IDLE):
		near_x = to_local(_player.global_position).x
		near_spread = 50.0
		rate = 70.0 if state == State.WARN else 4.0 + 26.0 * clampf(lit_time / light_hold_time, 0.0, 1.0)
	_bubble_acc += rate * delta
	while _bubble_acc >= 1.0:
		_bubble_acc -= 1.0
		var x: float = clampf(near_x + _rng.randf_range(-near_spread, near_spread),
				left_limit, bottom_half_width)
		var bubble_depth: float = depth if state != State.WARN else _rng.randf_range(6.0, depth)
		_bubbles.append({"x": x, "y": bubble_depth - 2.0, "r": _rng.randf_range(1.5, 4.0),
				"speed": _rng.randf_range(40.0, 90.0), "phase": _rng.randf_range(0.0, TAU)})
	for b: Dictionary in _bubbles:
		b["y"] = (b["y"] as float) - (b["speed"] as float) * delta
	for i: int in range(_bubbles.size() - 1, -1, -1):
		if (_bubbles[i]["y"] as float) <= 0.0:
			_pops.append({"x": _bubbles[i]["x"], "r": _bubbles[i]["r"], "t": 0.0})
			_bubbles.remove_at(i)
	for i: int in range(_pops.size() - 1, -1, -1):
		_pops[i]["t"] = (_pops[i]["t"] as float) + delta
		if (_pops[i]["t"] as float) > 0.25:
			_pops.remove_at(i)


func _spawn_splash(x: float) -> void:
	for i: int in 5:
		_pops.append({"x": x + _rng.randf_range(-14.0, 14.0), "r": _rng.randf_range(3.0, 6.0), "t": 0.0})


func _surface_y(x: float) -> float:
	var roil: float = 1.2
	if state == State.WARN:
		roil = 1.2 + 3.0 * warn_t / _warning_duration()
	elif state == State.STRIKE:
		roil = 5.0
	return sin(x * 0.07 + _time * 3.1) * roil * 0.6 + sin(x * 0.13 - _time * 4.7) * roil * 0.4


func _draw() -> void:
	# Liquid body: the surface follows a gentle wave; deeper part darker.
	var surface: PackedVector2Array = PackedVector2Array()
	var steps: int = 32
	for k: int in steps + 1:
		var x: float = lerpf(-half_width - entry_extension, half_width, float(k) / steps)
		surface.append(Vector2(x, _surface_y(x)))
	var body: PackedVector2Array = surface.duplicate()
	body.append(Vector2(bottom_half_width, depth))
	body.append(Vector2(-bottom_half_width - entry_extension, depth))
	draw_colored_polygon(body, ACID)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bottom_half_width - entry_extension + 6.0, depth * 0.55),
		Vector2(bottom_half_width - 6.0, depth * 0.55),
		Vector2(bottom_half_width, depth),
		Vector2(-bottom_half_width - entry_extension, depth)]), ACID_DEEP)

	if has_dense_bed:
		# The dense bed sits under a darker patch of acid.
		var bed: PackedVector2Array = PackedVector2Array()
		for k: int in steps + 1:
			var x: float = lerpf(danger_start, half_width, float(k) / steps)
			bed.append(Vector2(x, maxf(_surface_y(x) + 3.0, 3.0)))
		bed.append(Vector2(bottom_half_width, depth))
		bed.append(Vector2(danger_start + 30.0, depth))
		draw_colored_polygon(bed, Color(ACID_DEEP, 0.45))
		for i: int in 15:
			var bx: float = lerpf(danger_start + 10.0, bottom_half_width - 8.0, float(i) / 14.0)
			_draw_low_stalk(bx + sin(i * 2.7) * 6.0, 9.0 + 11.0 * absf(sin(i * 1.7)), i)
	if entry_stalk_reach > 0.0:
		var rise: float = 8.0 * clampf(warn_t / entry_warn_time, 0.0, 1.0) if state == State.WARN and _entry_warning else 0.0
		var pair_rise: float = rise if _warning_stalk == 0 else 0.0
		_draw_low_stalk(entry_stalk_x + ENTRY_STALK_OFFSETS[0], 13.0 + pair_rise, 2)
		_draw_low_stalk(entry_stalk_x + ENTRY_STALK_OFFSETS[1], 18.0 + pair_rise, 5)
		for i: int in single_stalks.size():
			_draw_low_stalk(single_stalks[i], 15.0 + (rise if _warning_stalk == i + 1 else 0.0), i + 6)

	# Shapes straining under the surface while he wades: plume crowns rising toward him.
	if _player != null and state != State.STRIKE and _in_danger:
		var px: float = to_local(_player.global_position).x
		var k: float = 1.0 if state == State.WARN else clampf(lit_time / light_hold_time, 0.0, 1.0)
		if not _player.is_torch_on:
			k = 1.0
		for i: int in 4:
			var ox: float = px + (float(i) - 1.5) * 26.0 + sin(_time * 3.0 + i) * 4.0
			var oy: float = lerpf(depth - 2.0, 4.0, k) + sin(_time * 7.0 + i * 1.7) * 1.5
			var c: Color = PLUME.darkened(0.35)
			c.a = 0.35 + 0.45 * k
			draw_circle(Vector2(ox, oy), 4.0 + 2.0 * k, c)

	for b: Dictionary in _bubbles:
		var bx: float = (b["x"] as float) + sin(_time * 6.0 + (b["phase"] as float)) * 1.2
		draw_arc(Vector2(bx, b["y"] as float), b["r"] as float, 0.0, TAU, 10, ACID_FOAM, 1.0, true)
	for pop: Dictionary in _pops:
		var t: float = (pop["t"] as float) / 0.25
		var c: Color = ACID_FOAM
		c.a = 1.0 - t
		var x: float = pop["x"] as float
		draw_arc(Vector2(x, _surface_y(x) - 1.0), (pop["r"] as float) * (1.0 + 1.6 * t), PI, TAU, 10, c, 1.3, true)

	draw_polyline(surface, Color(ACID_FOAM, 0.65), 2.0, true)

	# Ambush: worms burst out of the acid and close over him.
	if state == State.STRIKE:
		for s: Dictionary in _burst:
			var g: float = clampf((strike_t - (s["delay"] as float)) / 0.14, 0.0, 1.0)
			g = 1.0 - pow(1.0 - g, 3.0)
			var h: float = (s["height"] as float) * g
			if h < 2.0:
				continue
			var pts: PackedVector2Array = PackedVector2Array()
			for k: int in 11:
				var t: float = float(k) / 10.0
				var wob: float = sin(_time * 9.0 + (s["phase"] as float) + t * 3.0) * 6.0 * t
				var x: float = (s["x"] as float) + (s["lean"] as float) * h * t * t + wob
				pts.append(Vector2(x, depth * 0.5 - h * t))
			var th: float = s["thick"] as float
			draw_polyline(pts, BONE_EDGE, th + 3.0, true)
			draw_polyline(pts, BONE, th, true)
			var tip: Vector2 = pts[10]
			var fwd: Vector2 = (pts[10] - pts[9]).normalized()
			for i: int in 9:
				var a: float = (float(i) / 8.0 * 2.0 - 1.0) * 1.1
				var end: Vector2 = tip + fwd.rotated(a) * 18.0
				draw_line(tip, end, PLUME, 2.2, true)
				draw_circle(end, 1.6, PLUME.lightened(0.15))
			draw_circle(tip, th * 0.45, PLUME.darkened(0.25))
		# acid thrown up where they broke the surface
		var sc: Color = ACID_FOAM
		sc.a = clampf(1.0 - strike_t / 0.5, 0.0, 1.0)
		for i: int in 8:
			var a: float = -PI * (0.15 + 0.7 * float(i) / 7.0)
			var r: float = 20.0 + 70.0 * clampf(strike_t / 0.3, 0.0, 1.0)
			draw_circle(Vector2(_strike_x + cos(a) * r, sin(a) * r * 0.8), 3.0, sc)


func _draw_low_stalk(x: float, height: float, index: int) -> void:
	var lean: float = sin(_time * 1.6 + index * 2.3) * 3.0 + sin(index * 0.8) * 5.0
	var tip := Vector2(x + lean, _surface_y(x) - height)
	var stalk := PackedVector2Array([
		Vector2(x - 1.0, 14.0), Vector2(x, 4.0),
		Vector2(x + lean * 0.25, -height * 0.45), tip
	])
	draw_polyline(stalk, STALK_EDGE, 7.0, true)
	draw_polyline(stalk, STALK_SHADOW, 5.0, true)
	for i: int in 5:
		var direction: float = (i - 2) * 0.39 + lean * 0.05
		var plume: Vector2 = Vector2.UP.rotated(direction) * (8.0 - absf(i - 2))
		draw_line(tip, tip + plume, STALK_TIP, 2.0, true)
	draw_circle(tip, 2.5, STALK_TIP, true)
