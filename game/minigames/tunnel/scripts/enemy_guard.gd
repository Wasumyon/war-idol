class_name EnemyGuard
extends CharacterBody2D
## A patrolling guard with a hand lantern. Walks between two world-x points,
## waits, turns. Charges can extend beyond his patrol range. His cone has two bands
## (needs line of sight, not hidden):
##   - blue (outer): suspicion builds. Past blue_threshold he stops, stares
##     for notice_time, then charges to where you were AND past it
##     (overshoot), so standing in the open there means he runs into you.
##     Your own lamp, or standing in a lit_zone, in front of him counts as
##     blue out to lamp_sight_range even outside the cone.
##   - yellow (inner, or right in front of him): a catch meter fills; after
##     catch_time you're caught and lose a life.
## After a charge (or a noise) he's ALERT for alert_time: faster patrol,
## shorter waits, and suspicion builds faster.
## Touching him while not hidden is an instant death (back to the checkpoint).
## hear_noise(x) sends him to investigate a spot (see noise_lever.gd).
## The cone is also a light_source (retracts tubeworms, for Ch 4) and a
## guard_light (floor switches ignore it).
##
## Node origin = the guard's feet on the floor line.

signal spotted_player
signal caught_player

const GUARD_ANIMATION = preload("res://minigames/tunnel/scripts/guard_animation.gd")
const LIGHT_TEX: Texture2D = preload("res://minigames/tunnel/art/light_radial.tres")
const BODY_HALF_WIDTH: float = 23.0
const FLOOR_MASK: int = 1
const DOOR_MASK: int = 1 << 3
const FIRST_SIGHT_FLAG: String = "saw_first_ministry_guard"

@export_group("Patrol")
## World-x of the two turn points. He never goes past these.
@export var patrol_left: float = 1300.0
@export var patrol_right: float = 2500.0
@export var walk_speed: float = 95.0
@export var wait_time: float = 1.6
## 1 = starts walking right, -1 = left.
@export var start_facing: int = -1
## Plant his feet on gently sloped ground along the patrol.
@export var follow_floor: bool = false

@export_group("Vision")
## Outer edge of the cone (blue band).
@export var vision_range: float = 300.0
## Inner part of the cone (yellow band): stay here catch_time and you're caught.
@export var inner_range: float = 160.0
@export var cone_half_angle_deg: float = 22.0
## Your own lamp (or standing in a lit pool) in front of him is seen this far,
## even outside the cone. Counts as blue.
@export var lamp_sight_range: float = 420.0
## Right in front of him counts as yellow even in the dark.
@export var close_range: float = 110.0
## Seconds in the yellow band before he catches you.
@export var catch_time: float = 1.0
## Lantern position relative to the feet, for facing right.
@export var lantern_offset: Vector2 = Vector2(12, -50)

@export_group("Charge")
## Extra ground he can chase across beyond either end of his normal patrol.
@export var chase_margin_left: float = 0.0
@export var chase_margin_right: float = 0.0
## Seconds in blue before he notices (calm / alert).
@export var blue_threshold: float = 0.35
@export var blue_threshold_alert: float = 0.15
## The pause when he notices you, before he charges.
@export var notice_time: float = 0.5
@export var charge_speed: float = 280.0
## How far past your position he runs.
@export var overshoot: float = 220.0

@export_group("Alert")
@export var alert_time: float = 8.0
@export var alert_walk_speed: float = 150.0
@export var alert_wait_time: float = 0.6
## At a noise or the end of a charge he looks each way this long.
@export var look_time: float = 0.7

@export_group("Voice")
## Said (glitched, above him and over the fade) when he catches you in his light.
@export var catch_line: String = "There you are."
## Said when you bump into him.
@export var touch_line: String = "Gotcha, rat."
## The player speaks this once, when this guard first comes into view.
@export_multiline var first_sight_line: String = ""

@export_group("Touch")
## Bumping into him (not hidden) kills you. Half-width / height of his body.
@export var touch_half_width: float = 34.0
@export var touch_height: float = 150.0

enum State { WALK, WAIT, NOTICE, CHARGE, INVESTIGATE, LOOK, CAUGHT }
enum Sight { NONE, BLUE, YELLOW }

const BLUE_COL: Color = Color(0.85, 0.75, 0.6, 0.13)
const YELLOW_COL: Color = Color(1.0, 0.8, 0.35, 0.16)
const RED_COL: Color = Color(1.0, 0.25, 0.15, 0.24)

var state: State = State.WALK
var facing: int = -1
var sight: Sight = Sight.NONE
var _wait_timer: float = 0.0
var _catch: float = 0.0
## Suspicion: seconds spent in blue, drains when unseen.
var _suspicion: float = 0.0
var _alert: float = 0.0
var _target_x: float = 0.0
var _looks_left: int = 0
var _walk_phase: float = 0.0
var _player: Player
var _vent_sprint: float = 0.0
var _stalk_dodge_x: float = NAN


## Hurry past a rattling vent without interrupting pursuit or changing direction.
func hurry_past_vent(duration: float = 1.0) -> void:
	_vent_sprint = maxf(_vent_sprint, duration)


## Clear the strike's reach with a short burst, then resume the current action.
func step_clear_of_stalks(center_x: float, reach: float) -> void:
	if state == State.CAUGHT or not is_nan(_stalk_dodge_x):
		return
	var direction: float = float(facing)
	if state == State.WAIT or state == State.LOOK or state == State.NOTICE:
		var offset: float = global_position.x - center_x
		if not is_zero_approx(offset):
			direction = signf(offset)
	_stalk_dodge_x = center_x + direction * (reach + 8.0)

var _visual: Node2D
var _sprite: GUARD_ANIMATION
var _cone_area: Area2D
var _cone_shape: CollisionPolygon2D
var _outer_glow: Polygon2D
var _inner_glow: Polygon2D
var _lantern_light: PointLight2D
var _beam_light: PointLight2D
var _alert_label: Label
var _speech: GlitchText
var _noticed_player_lamp: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = DOOR_MASK
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(BODY_HALF_WIDTH * 2.0, 110.0)
	var body := CollisionShape2D.new()
	body.shape = body_shape
	body.position.y = -55.0
	add_child(body)
	var footsteps = preload("res://minigames/tunnel/scripts/footsteps.gd").new()
	footsteps.heavy = true
	add_child(footsteps)
	add_to_group("guard")
	facing = 1 if start_facing >= 0 else -1
	_build()
	_apply_facing()


func is_alert() -> bool:
	return _alert > 0.0


## A noise at world-x: he goes to look (alert), unless he's already charging.
func hear_noise(x: float) -> void:
	if state == State.CAUGHT or state == State.CHARGE or state == State.NOTICE:
		return
	_alert = alert_time
	_target_x = clampf(x, patrol_left, patrol_right)
	state = State.INVESTIGATE


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	_check_player_sees_guard()

	var prev_sight: Sight = sight
	sight = Sight.NONE if state == State.CAUGHT else _sight_of_player()
	if sight != Sight.NONE and prev_sight == Sight.NONE:
		spotted_player.emit()

	# Suspicion from the blue band starts the notice -> charge. Yellow holds it
	# (the catch meter handles yellow), unseen drains it.
	var calm_states: bool = state == State.WALK or state == State.WAIT \
			or state == State.INVESTIGATE or state == State.LOOK
	if sight == Sight.BLUE:
		_suspicion += delta
	elif sight == Sight.NONE:
		_suspicion = maxf(_suspicion - delta, 0.0)
	var threshold: float = blue_threshold_alert if is_alert() else blue_threshold
	if calm_states and sight != Sight.NONE and _suspicion >= threshold:
		state = State.NOTICE
		_wait_timer = notice_time
		_set_facing(1 if _player.global_position.x >= global_position.x else -1)

	if _alert > 0.0 and state != State.CHARGE and state != State.NOTICE:
		_alert = maxf(_alert - delta, 0.0)
	var speed: float = alert_walk_speed if is_alert() else walk_speed
	if _vent_sprint > 0.0:
		_vent_sprint = maxf(0.0, _vent_sprint - delta)
		speed = maxf(speed, charge_speed)

	var dodging: bool = state != State.CAUGHT and not is_nan(_stalk_dodge_x)
	if dodging:
		var blocked: bool = _step_toward(_stalk_dodge_x, charge_speed * delta, delta, 13.0)
		if blocked or is_equal_approx(global_position.x, _stalk_dodge_x):
			_stalk_dodge_x = NAN
	else:
		_advance_movement(delta, speed)
	if follow_floor:
		var feet: Vector2 = global_position
		var query := PhysicsRayQueryParameters2D.create(feet + Vector2(0.0, -36.0),
				feet + Vector2(0.0, 36.0), FLOOR_MASK)
		var floor_hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not floor_hit.is_empty():
			global_position.y = (floor_hit["position"] as Vector2).y

	if state != State.CAUGHT and _touching_player():
		_touch_kill()

	# Catch meter: fills in the yellow band, drains outside it.
	if state != State.CAUGHT:
		if sight == Sight.YELLOW:
			_catch += delta
			if _catch >= catch_time:
				_catch_player()
		else:
			_catch = maxf(_catch - delta * 1.5, 0.0)

	_update_visual(dodging)


func _advance_movement(delta: float, speed: float) -> void:
	match state:
		State.WALK:
			var target: float = patrol_right if facing > 0 else patrol_left
			# After chasing outside the patrol, walk back facing the way we move.
			if global_position.x < patrol_left:
				target = patrol_left
				_set_facing(1)
			elif global_position.x > patrol_right:
				target = patrol_right
				_set_facing(-1)
			var blocked: bool = _step_toward(target, speed * delta, delta, 9.0 if is_alert() else 7.0)
			if blocked or is_equal_approx(global_position.x, target):
				state = State.WAIT
				_wait_timer = alert_wait_time if is_alert() else wait_time
		State.WAIT:
			_settle_walk(delta)
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				_set_facing(-facing)
				state = State.WALK
		State.NOTICE:
			_settle_walk(delta)
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				# Charge to where you are now, and past it. Fixed target, so he
				# always arrives and never gets stuck staring.
				var px: float = _player.global_position.x if _player else global_position.x
				_target_x = clampf(px + overshoot * float(facing),
						patrol_left - chase_margin_left, patrol_right + chase_margin_right)
				if not is_equal_approx(_target_x, global_position.x):
					_set_facing(1 if _target_x > global_position.x else -1)
				_alert = alert_time
				_suspicion = 0.0
				state = State.CHARGE
		State.CHARGE:
			# Keep pursuing a visible player across both vision bands. Only
			# search the last known position once they actually break sight.
			if sight != Sight.NONE:
				_target_x = clampf(_player.global_position.x + overshoot * float(facing),
						patrol_left - chase_margin_left, patrol_right + chase_margin_right)
			var blocked: bool = _step_toward(_target_x, charge_speed * delta, delta, 13.0)
			if is_equal_approx(global_position.x, _target_x) or (blocked and sight == Sight.NONE):
				_start_look()
		State.INVESTIGATE:
			var dx: float = _target_x - global_position.x
			if absf(dx) > 1.0:
				_set_facing(1 if dx > 0.0 else -1)
			var blocked: bool = _step_toward(_target_x, speed * delta, delta, 9.0)
			if blocked or is_equal_approx(global_position.x, _target_x):
				_start_look()
		State.LOOK:
			_settle_walk(delta)
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				_looks_left -= 1
				if _looks_left > 0:
					_set_facing(-facing)
					_wait_timer = look_time
				else:
					state = State.WALK  # carries on the way he's facing
					_noticed_player_lamp = false
		State.CAUGHT:
			_settle_walk(delta)


func _start_look() -> void:
	state = State.LOOK
	_wait_timer = look_time
	_looks_left = 3  # this way, back, this way again


func _step_toward(target: float, distance: float, delta: float, phase_rate: float) -> bool:
	var start: float = global_position.x
	var dx: float = move_toward(start, target, distance) - start
	var collision: KinematicCollision2D = move_and_collide(Vector2(dx, 0.0))
	if absf(global_position.x - start) > 0.05:
		_walk_phase += delta * phase_rate
	else:
		_settle_walk(delta)
	return collision != null


func _settle_walk(delta: float) -> void:
	_walk_phase = lerpf(_walk_phase, roundf(_walk_phase / PI) * PI, delta * 8.0)


func _check_player_sees_guard() -> void:
	if first_sight_line.is_empty() or GameManager.flags.has(FIRST_SIGHT_FLAG) \
			or _player == null or _player.is_dead or GameManager.is_transitioning():
		return
	var chest := Vector2(0.0, -65.0)
	var guard_center: Vector2 = global_position + chest
	var screen_position: Vector2 = get_canvas_transform() * guard_center
	if get_viewport_rect().grow(-30.0).has_point(screen_position) \
			and _has_line_of_sight(_player.global_position + chest, guard_center):
		GameManager.flags[FIRST_SIGHT_FLAG] = true
		_player.speak(first_sight_line, 3.5)


## Which band of his sight the player is in right now (NONE if unseen).
func _sight_of_player() -> Sight:
	if _player == null or _player.is_dead or _player.is_hidden:
		return Sight.NONE
	var eye: Vector2 = _lantern_global()
	var target: Vector2 = _player.global_position + Vector2(0, -50)
	var rel: Vector2 = target - eye
	if rel.x * float(facing) <= 0.0:
		return Sight.NONE  # behind him

	var dist: float = rel.length()
	var in_angle: bool = absf(rel.angle_to(Vector2(facing, 0))) <= deg_to_rad(cone_half_angle_deg)
	var result: Sight = Sight.NONE
	if absf(rel.x) < close_range and absf(rel.y) < 140.0:
		result = Sight.YELLOW
	elif in_angle and dist <= inner_range:
		result = Sight.YELLOW
	elif in_angle and dist <= vision_range:
		result = Sight.BLUE
	elif dist <= lamp_sight_range and absf(rel.y) < 160.0 \
			and (_player.lamp_seen_from(eye) or _player_in_lit_zone()):
		result = Sight.BLUE
	if result == Sight.NONE or not _has_line_of_sight(eye, target):
		return Sight.NONE
	if dist <= lamp_sight_range and _player.lamp_seen_from(eye):
		_noticed_player_lamp = true
	# The guard can spot and pursue through a grille but must reach the player to catch him.
	if result == Sight.YELLOW and _door_between_player():
		return Sight.BLUE
	return result


func _touching_player() -> bool:
	if _player == null or _player.is_dead or _player.is_hidden:
		return false
	var rel: Vector2 = _player.global_position - global_position
	return absf(rel.x) <= touch_half_width and absf(rel.y) <= touch_height \
			and not _door_between_player()


func _door_between_player() -> bool:
	var chest := Vector2(0.0, -50.0)
	var query := PhysicsRayQueryParameters2D.create(global_position + chest,
			_player.global_position + chest, DOOR_MASK)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _touch_kill() -> void:
	caught_player.emit()
	if GameManager.god_mode:
		return
	state = State.CAUGHT
	_set_facing(1 if _player.global_position.x >= global_position.x else -1)
	_say(touch_line)
	_kill_player()


func _player_in_lit_zone() -> bool:
	for zone: Node in get_tree().get_nodes_in_group("lit_zone"):
		if zone.has_method("contains_player") and zone.call("contains_player", _player):
			return true
	return false


func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, 0b1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _catch_player() -> void:
	caught_player.emit()
	# God mode: the meter flashes full but he keeps going.
	if GameManager.god_mode:
		_catch = 0.0
		return
	state = State.CAUGHT
	if _player:
		_set_facing(1 if _player.global_position.x >= global_position.x else -1)
		_say(catch_line)
	_kill_player()


func _kill_player() -> void:
	var hint: String = GameManager.GUARD_LAMP_HINT if _noticed_player_lamp else GameManager.GUARD_HINT
	_player.kill(self, hint)


func _say(line: String) -> void:
	if line == "":
		return
	_speech.say(line, 2.0)
	GameManager.set_death_line(line)


func _lantern_global() -> Vector2:
	return global_position + Vector2(lantern_offset.x * facing, lantern_offset.y)


func _set_facing(dir: int) -> void:
	if dir == facing:
		return
	facing = dir
	_apply_facing()


func _apply_facing() -> void:
	if _visual == null:
		return
	_visual.scale.x = float(facing)
	var lantern: Vector2 = Vector2(lantern_offset.x * facing, lantern_offset.y)
	_cone_shape.set_deferred("polygon", _sector(lantern, 0.0, vision_range))
	_inner_glow.polygon = _sector(lantern, 0.0, inner_range)
	_outer_glow.polygon = _sector(lantern, inner_range, vision_range)
	_lantern_light.position = lantern
	_beam_light.position = lantern + Vector2(vision_range * 0.5 * facing, 0)


## A slice of the cone between two distances (r0 = 0 gives a full wedge).
func _sector(origin: Vector2, r0: float, r1: float) -> PackedVector2Array:
	var half: float = deg_to_rad(cone_half_angle_deg)
	var steps: int = 8
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in steps + 1:
		var ang: float = lerpf(-half, half, float(i) / float(steps))
		pts.append(origin + Vector2(cos(ang) * facing, sin(ang)) * r1)
	if r0 <= 0.0:
		pts.append(origin)
	else:
		for i: int in range(steps, -1, -1):
			var ang: float = lerpf(-half, half, float(i) / float(steps))
			pts.append(origin + Vector2(cos(ang) * facing, sin(ang)) * r0)
	return pts


func _update_visual(dodging: bool) -> void:
	var moving: bool = dodging or state == State.WALK or state == State.CHARGE or state == State.INVESTIGATE
	_sprite.animate(get_physics_process_delta_time(), moving, dodging or state == State.CHARGE,
			1.35 if is_alert() else 1.0)
	var t: float = clampf(_catch / catch_time, 0.0, 1.0)
	# "?" while suspicious / searching, "!" when he's noticed you (fills red
	# with the catch meter).
	var noticed: bool = state == State.NOTICE or state == State.CHARGE or state == State.CAUGHT
	_alert_label.visible = noticed or sight != Sight.NONE or t > 0.0 \
			or state == State.INVESTIGATE or state == State.LOOK
	_alert_label.text = "!" if noticed or t > 0.0 else "?"
	_alert_label.modulate = Color(1, 0.85, 0.3).lerp(Color(1, 0.2, 0.15), t)
	_alert_label.scale = Vector2.ONE * (0.8 + 0.5 * t)
	_inner_glow.color = YELLOW_COL.lerp(RED_COL, t)
	var outer: Color = BLUE_COL
	if sight == Sight.BLUE:
		outer.a = 0.2
	if is_alert():
		outer = outer.lerp(Color(1.0, 0.5, 0.28, outer.a + 0.04), 0.5)
	_outer_glow.color = outer


func _build() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)

	_sprite = GUARD_ANIMATION.new()
	_sprite.name = "Sprite"
	_visual.add_child(_sprite)

	# Visible beam: additive, unshaded so the darkness doesn't eat it.
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_outer_glow = Polygon2D.new()
	_outer_glow.name = "OuterGlow"
	_outer_glow.material = mat
	_outer_glow.z_index = 2
	add_child(_outer_glow)
	_inner_glow = Polygon2D.new()
	_inner_glow.name = "InnerGlow"
	_inner_glow.material = mat
	_inner_glow.z_index = 2
	add_child(_inner_glow)

	_lantern_light = PointLight2D.new()
	_lantern_light.name = "LanternLight"
	_lantern_light.texture = LIGHT_TEX
	_lantern_light.color = Color(1.0, 0.75, 0.45)
	_lantern_light.energy = 0.9
	_lantern_light.texture_scale = 0.7
	add_child(_lantern_light)

	_beam_light = PointLight2D.new()
	_beam_light.name = "BeamLight"
	_beam_light.texture = LIGHT_TEX
	_beam_light.color = Color(1.0, 0.75, 0.45)
	_beam_light.energy = 0.55
	_beam_light.texture_scale = 1.1
	add_child(_beam_light)

	# Vision cone as a light area (layer 3).
	_cone_area = Area2D.new()
	_cone_area.name = "ConeArea"
	_cone_area.collision_layer = 0b100
	_cone_area.collision_mask = 0
	_cone_area.monitoring = false
	_cone_area.monitorable = true
	_cone_area.add_to_group("light_source")
	_cone_area.add_to_group("guard_light")
	add_child(_cone_area)
	_cone_shape = CollisionPolygon2D.new()
	_cone_shape.name = "Shape"
	_cone_area.add_child(_cone_shape)

	_alert_label = Label.new()
	_alert_label.name = "Alert"
	_alert_label.text = "!"
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

	_speech = GlitchText.make_world_speech(self, Vector2(0, -205))
