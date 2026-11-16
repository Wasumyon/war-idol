class_name Player
extends CharacterBody2D
## The MC: walks left/right (no jumping, he has one leg), carries the lamp, can hide at hide spots.
## Scene origin is at his feet, so place him with his position on the floor line.

signal torch_toggled(is_on: bool)
signal hidden_changed(is_hidden: bool)
## Scripted walk (cutscenes) reached its target.
signal walk_arrived

@export_group("Movement")
@export var max_speed: float = 250.0  # was 221
@export var acceleration: float = 1620.0  # scaled with speed
@export var deceleration: float = 2350.0  # scaled with speed
## Terminal falling speed (px/s). Room 0 lowers it so the fall down the vent lasts a few seconds.
@export var max_fall_speed: float = 100000.0

@export_group("Sprint")
## Hold Shift for a short burst. He limps, but he can hurry.
@export var sprint_mult: float = 1.45
## Seconds of sprint on a full bar.
@export var stamina_duration: float = 1.9
## Seconds to refill an empty bar, after regen_delay.
@export var stamina_regen_time: float = 2.5
@export var stamina_regen_delay: float = 0.6
## Once emptied he's winded: no sprint until the bar is back to this fraction.
@export var winded_until: float = 0.4

@export_group("Animation")
## Ground speed (px/s) of each clip at normal playback. The clip plays at
## (his speed / this), so his feet stay planted. Lower = slower legs, some foot slide.
@export var walk_stride_speed: float = 160.0
## Limp: only before he has the lamp (Room 0).
@export var limp_stride_speed: float = 125.0
@export var sprint_stride_speed: float = 360.0

@export_group("Lamp")
## False until he takes the lamp from the corpse (Chamber 0). Chamber 1 starts with it.
@export var has_torch: bool = true
@export var torch_starts_on: bool = false
## How much the lamp's energy wobbles, as a fraction of its base energy.
@export var flicker_strength: float = 0.14
@export var flicker_speed: float = 7.0

@export_group("Lamp beam")
## Test: the lamp throws a forward cone instead of a round glow. L toggles it while playtesting.
@export var lamp_directional: bool = true
## Beam reach (px) of the light you see, and of what it touches (worms, switches).
@export var beam_range: float = 560.0
@export var beam_reach: float = 470.0
@export var beam_half_angle_deg: float = 30.0
## Tilted down a touch so the floor ahead is lit.
@export var beam_tilt_deg: float = 9.0
## Small glow round him that touches things on both sides (feet, a wall at his back).
@export var spill_radius: float = 80.0
## Guards see the lamp from behind him only this close (the spill, not the beam).
@export var lamp_seen_behind_range: float = 220.0

var is_torch_on: bool = false
var is_hidden: bool = false
var is_dead: bool = false
var _worm_recovery: float = 0.0
## Chambers turn this off for cutscenes (the fall, sitting at the furnace).
var controls_enabled: bool = true
## Pool underfoot, used for traction when reversing direction.
var acid_pool: AcidPool
## Cutscenes: force a sprite animation (e.g. &"hide" for the crouch after landing). Empty = automatic.
var anim_override: StringName = &""
var facing: int = 1
## 0..1. Shown as a small bar over his head when not full.
var stamina: float = 1.0
var is_sprinting: bool = false
var _winded: bool = false
var _regen_wait: float = 0.0
var _stamina_bar: Node2D
## Cutscenes: walk him to this world-x with controls off (NAN = none).
var _auto_target_x: float = NAN
## Cutscenes: he sits (e.g. by the furnace in Chamber 5).
var is_sitting: bool = false
var _sit: float = 0.0
var _stamina_fill: ColorRect

## How many HideZones he is currently standing in.
var _hide_zone_count: int = 0
var _action_prompt: Label
## z_index the chamber placed him at; hiding drops him one below it.
var _base_z: int = 0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _base_energy: float = 1.0
var _base_scale: float = 1.0
var _base_color: Color = Color.WHITE
var _radial_tex: Texture2D
var _cone_tex: Texture2D = preload("res://art/light_cone.png")
var _round_shape: Shape2D
var _beam_shape: ConvexPolygonShape2D
var _spill_shape: CollisionShape2D
var _shape_facing: int = 0
## While > 0 a guard has noticed the lamp: it flickers red.
var _alarm: float = 0.0
## Was the lamp on when he hid? Restored when he steps out.
var _lamp_before_hide: bool = false
## A relight is queued (he just stepped out); counts as "lamp on" if he re-hides.
var _relight_pending: bool = false
## Delay before the lamp relights after leaving a hide spot (reads as deliberate).
const RELIGHT_DELAY: float = 0.15
const TORCH_HANDS = preload("res://art/sprites/mc/model/torch_hand_positions.gd").HANDS
const SPEECH_BUBBLE = preload("res://scripts/chip_objective.gd")

@onready var _visual: Node2D = $Visual
@onready var _body: Node2D = $Visual/Body
@onready var _sprite: AnimatedSprite2D = $Visual/Body/Sprite
@onready var _torch_light: PointLight2D = $Visual/TorchLight
@onready var _light_area: Area2D = $Visual/TorchLight/LightArea
@onready var _lamp_glow: Polygon2D = $Visual/Body/LampGlow
@onready var _lantern: Sprite2D = $Visual/Body/Lantern
@onready var _light_shape: CollisionShape2D = $Visual/TorchLight/LightArea/Shape


func _ready() -> void:
	var footsteps = preload("res://scripts/footsteps.gd").new()
	add_child(footsteps)
	add_to_group("player")
	GameManager.respawn_hint.connect(_show_respawn_hint)
	_base_z = z_index
	if GameManager.has_checkpoint:
		global_position = GameManager.checkpoint
	_noise.seed = randi()
	_noise.frequency = 0.9
	_base_energy = _torch_light.energy
	_base_scale = _torch_light.texture_scale
	_base_color = _torch_light.color
	_radial_tex = _torch_light.texture
	_round_shape = _light_shape.shape
	_beam_shape = ConvexPolygonShape2D.new()
	_spill_shape = CollisionShape2D.new()
	var spill: CircleShape2D = CircleShape2D.new()
	spill.radius = spill_radius
	_spill_shape.shape = spill
	_light_area.add_child(_spill_shape)
	# The area is laid out in world orientation (not flipped with the sprite).
	_light_area.top_level = true
	_set_lamp_mode(lamp_directional)
	_apply_torch(torch_starts_on and has_torch)
	_build_stamina_bar()
	_build_action_prompt()
	_sprite.frame_changed.connect(_update_lantern_attachment)
	_update_visual(0.0)
	_update_light_area()


func _physics_process(delta: float) -> void:
	_worm_recovery = maxf(0.0, _worm_recovery - delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity * delta, max_fall_speed)

	var input_dir: float = 0.0
	if _can_act():
		input_dir = Input.get_axis("ui_left", "ui_right")
	elif not is_nan(_auto_target_x):
		var dx: float = _auto_target_x - global_position.x
		if absf(dx) <= 4.0:
			_auto_target_x = NAN
			walk_arrived.emit()
		else:
			input_dir = signf(dx) * 0.6  # a slow, tired walk

	# Walking while hidden steps him back out of hiding.
	if is_hidden and input_dir != 0.0:
		set_hidden(false)

	if is_hidden:
		input_dir = 0.0

	_update_stamina(delta, input_dir != 0.0)
	var speed_mult: float = GameManager.god_speed_mult
	if is_sprinting:
		speed_mult *= sprint_mult
	if input_dir != 0.0:
		var grip: float = acid_pool.reverse_grip if is_instance_valid(acid_pool) and input_dir * velocity.x < 0.0 else 1.0
		velocity.x = move_toward(velocity.x, input_dir * max_speed * speed_mult, acceleration * speed_mult * grip * delta)
		facing = 1 if input_dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	move_and_slide()

	if _can_act():
		if Input.is_action_just_pressed("action_torch") and has_torch and not is_hidden:
			set_torch(not is_torch_on)
		if Input.is_action_just_pressed("action_hide"):
			if is_hidden:
				set_hidden(false)
			elif can_hide():
				set_hidden(true)

	_update_action_prompt()
	_update_visual(delta)
	_update_light_area()


func _unhandled_input(event: InputEvent) -> void:
	# Playtest: L flips between the cone and the old round glow.
	if event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_L:
		_set_lamp_mode(not lamp_directional)
		print("Lamp: ", "cone" if lamp_directional else "round")


func _set_lamp_mode(directional: bool) -> void:
	lamp_directional = directional
	_shape_facing = 0
	if directional:
		_torch_light.texture = _cone_tex
		_base_scale = beam_range / (_cone_tex.get_width() * 0.5)
		_torch_light.rotation = deg_to_rad(beam_tilt_deg)
		_light_shape.shape = _beam_shape
		_spill_shape.disabled = false
	else:
		_torch_light.texture = _radial_tex
		_base_scale = 1.3
		_torch_light.rotation = 0.0
		_light_shape.shape = _round_shape
		_spill_shape.disabled = true
	_torch_light.texture_scale = _base_scale


## Keep the light area on the lantern, and the beam wedge pointing the way he faces.
func _update_light_area() -> void:
	_light_area.global_position = _torch_light.global_position
	_light_area.global_rotation = 0.0
	_light_area.global_scale = Vector2.ONE
	if not lamp_directional or _shape_facing == facing:
		return
	_shape_facing = facing
	var pts: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
	var steps: int = 6
	for i in steps + 1:
		var a: float = deg_to_rad(beam_tilt_deg) + deg_to_rad(beam_half_angle_deg) * (2.0 * i / steps - 1.0)
		pts.append(Vector2(cos(a) * beam_reach * facing, sin(a) * beam_reach))
	if facing < 0:
		pts.reverse()
	_beam_shape.points = pts


## Can someone standing at world_pos see the lamp? Always, with the round glow.
## With the beam: if he's pointing it their way, or they're close enough to see the spill.
func lamp_seen_from(world_pos: Vector2) -> bool:
	if not is_torch_on or is_dead:
		return false
	if not lamp_directional:
		return true
	var dx: float = world_pos.x - global_position.x
	if dx * float(facing) >= 0.0:
		return true
	return absf(dx) <= lamp_seen_behind_range


func _process(delta: float) -> void:
	_time += delta
	if is_torch_on:
		# Organic flicker: smooth noise, plus a rare sharp dip like a failing cell.
		var n: float = _noise.get_noise_1d(_time * flicker_speed)
		var dip: float = 0.35 if randf() < 0.004 else 0.0
		_torch_light.energy = _base_energy * (1.0 + n * flicker_strength - dip)
		_torch_light.texture_scale = _base_scale * (1.0 + n * flicker_strength * 0.25)
	if _alarm > 0.0:
		_alarm -= delta
		var on: bool = fmod(_time, 0.16) < 0.09
		_torch_light.color = Color(1.0, 0.25, 0.2) if on else _base_color
		_lamp_glow.modulate = Color(1.0, 0.3, 0.25) if on else Color.WHITE
		if _alarm <= 0.0:
			_torch_light.color = _base_color
			_lamp_glow.modulate = Color.WHITE


func set_torch(on: bool) -> void:
	if on == is_torch_on:
		return
	_apply_torch(on)
	torch_toggled.emit(is_torch_on)


func set_hidden(value: bool) -> void:
	if value == is_hidden:
		return
	is_hidden = value
	# Tucked into the shadow he draws one layer back, so a guard walking past passes in front of him.
	z_index = _base_z - 1 if is_hidden else _base_z
	if is_hidden:
		# Hugging the wall: lamp shielded, no movement.
		_lamp_before_hide = is_torch_on or _relight_pending
		_relight_pending = false
		set_torch(false)
		velocity.x = 0.0
	elif _lamp_before_hide:
		# Stepping out: put the lamp back the way it was.
		_lamp_before_hide = false
		_relight_pending = true
		get_tree().create_timer(RELIGHT_DELAY).timeout.connect(_relight_after_hide)
	hidden_changed.emit(is_hidden)


func _relight_after_hide() -> void:
	if not _relight_pending or is_hidden or is_dead or not has_torch:
		return
	_relight_pending = false
	set_torch(true)


## Lose a life and let GameManager choose the respawn point.
func kill(hazard: Node = null, hint: String = "", force: bool = false) -> void:
	if is_dead or (GameManager.god_mode and not force):
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_torch(false)
	GameManager.respawn_player(hazard, hint, true)


func can_take_worm_hit() -> bool:
	return not is_dead and not is_hidden and not GameManager.god_mode \
			and not GameManager.is_transitioning() and _worm_recovery <= 0.0


## Recover locally while a heart remains. The landing x is chosen by the hazard.
func take_worm_hit(hazard: Node, hint: String, landing_x: float) -> void:
	if not can_take_worm_hit():
		return
	if GameManager.lives <= 1:
		kill(hazard, hint)
		return
	var origin: Vector2 = global_position
	var floor_ray := PhysicsRayQueryParameters2D.create(Vector2(landing_x, origin.y - 100.0),
			Vector2(landing_x, origin.y + 120.0), 1)
	var floor_hit := get_world_2d().direct_space_state.intersect_ray(floor_ray)
	if floor_hit.is_empty():
		kill(hazard, hint)
		return
	var landing: Vector2 = floor_hit["position"]
	var next_hint: String = GameManager.spend_life(hazard, hint)
	_worm_recovery = 1.0
	global_position = landing + Vector2.UP
	velocity = Vector2.ZERO
	controls_enabled = true
	# Ease the sprite into the landing while collision is already on clear ground.
	_visual.position.x = clampf(origin.x - landing.x, -90.0, 90.0)
	_visual.position.y = -16.0
	var recoil := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	recoil.tween_property(_visual, "position", Vector2.ZERO, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	hit_flash()
	if not next_hint.is_empty():
		_show_respawn_hint(next_hint)


func _show_respawn_hint(line: String) -> void:
	SPEECH_BUBBLE.show_line(self, line, 6.0, "RespawnHint")


func speak(line: String, duration: float, offset: Vector2 = Vector2(24, -239)) -> void:
	var previous: Node = get_node_or_null("PlayerSpeech")
	if previous:
		remove_child(previous)
		previous.queue_free()
	SPEECH_BUBBLE.show_line(self, line, duration, "PlayerSpeech", offset)


## A guard has noticed the lamp: flicker it red for `seconds` (keep calling).
func lamp_alarm(seconds: float) -> void:
	_alarm = maxf(_alarm, seconds)


## Stop him dead (a guard has him in his sights). Controls off, no slide.
func freeze() -> void:
	controls_enabled = false
	velocity = Vector2.ZERO
	if is_sprinting:
		is_sprinting = false


## Shot / struck: a hard red flash on his body.
func hit_flash() -> void:
	_visual.modulate = Color(3.0, 0.4, 0.3)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color(1.0, 0.35, 0.3), 0.25)


## Called by HideZone when he walks in or out of a hiding spot.
func enter_hide_zone() -> void:
	_hide_zone_count += 1


func exit_hide_zone() -> void:
	_hide_zone_count = maxi(_hide_zone_count - 1, 0)
	if _hide_zone_count == 0 and is_hidden:
		set_hidden(false)


func can_hide() -> bool:
	return _hide_zone_count > 0


func _can_act() -> bool:
	return controls_enabled and not is_dead and _worm_recovery <= 0.75 and not GameManager.is_transitioning()


func _apply_torch(on: bool) -> void:
	is_torch_on = on
	_torch_light.enabled = on
	_torch_light.energy = _base_energy
	_lamp_glow.visible = on
	# The light area is what tubeworms and sensors detect. Deferred because
	# physics state can't change mid-callback.
	_light_area.set_deferred("monitorable", on)


func _update_stamina(delta: float, moving: bool) -> void:
	is_sprinting = moving and not _winded and stamina > 0.0 \
			and _can_act() and Input.is_action_pressed("sprint")
	if is_sprinting:
		stamina = maxf(stamina - delta / stamina_duration, 0.0)
		_regen_wait = stamina_regen_delay
		if stamina <= 0.0:
			_winded = true
	else:
		_regen_wait -= delta
		if _regen_wait <= 0.0:
			stamina = minf(stamina + delta / stamina_regen_time, 1.0)
		if _winded and stamina >= winded_until:
			_winded = false
	if _stamina_bar:
		_stamina_bar.visible = stamina < 1.0
		_stamina_fill.size.x = 40.0 * stamina
		_stamina_fill.color = Color(0.85, 0.35, 0.25) if _winded else Color(0.93, 0.78, 0.5)


func _build_action_prompt() -> void:
	_action_prompt = Label.new()
	_action_prompt.name = "ActionPrompt"
	_action_prompt.offset_left = -80.0
	_action_prompt.offset_right = 80.0
	_action_prompt.offset_top = -182.0
	_action_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_prompt.z_as_relative = false
	_action_prompt.z_index = 5
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_action_prompt.material = unshaded
	_action_prompt.add_theme_font_size_override("font_size", 16)
	_action_prompt.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	_action_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_action_prompt.add_theme_constant_override("outline_size", 3)
	_action_prompt.modulate.a = 0.75
	_action_prompt.text = "W"
	_action_prompt.hide()
	add_child(_action_prompt)


func _update_action_prompt() -> void:
	_action_prompt.visible = _can_act() and not is_hidden and can_hide()


func _build_stamina_bar() -> void:
	_stamina_bar = Node2D.new()
	_stamina_bar.name = "StaminaBar"
	_stamina_bar.position = Vector2(-20, -150)
	_stamina_bar.z_index = 5
	_stamina_bar.visible = false
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_stamina_bar.material = mat
	add_child(_stamina_bar)
	var back: ColorRect = ColorRect.new()
	back.size = Vector2(40, 5)
	back.color = Color(0, 0, 0, 0.6)
	back.use_parent_material = true
	_stamina_bar.add_child(back)
	_stamina_fill = ColorRect.new()
	_stamina_fill.size = Vector2(40, 5)
	_stamina_fill.use_parent_material = true
	_stamina_bar.add_child(_stamina_fill)


## Sprite animation from the 3D model renders (art/sprites/mc/model/).
## The clip plays at the rate his feet would really cover the ground, so they don't slide.
func _update_visual(delta: float) -> void:
	_visual.scale.x = float(facing)
	var speed: float = absf(velocity.x)
	var anim: StringName = &"idle"
	var rate: float = 1.0
	if anim_override != &"":
		anim = anim_override
	elif not is_on_floor() and velocity.y > 150.0:
		anim = &"fall"
	elif is_hidden:
		anim = &"hide"
	elif is_sitting or _sit > 0.0:
		anim = &"idle"
	elif speed > 8.0:
		if is_sprinting:
			anim = &"sprint"
			rate = speed / sprint_stride_speed
		elif not has_torch:
			# Hurt from the fall: he limps until he finds the lamp.
			anim = &"limp"
			rate = speed / limp_stride_speed
		else:
			anim = &"walk"
			rate = speed / walk_stride_speed
	# Use the model's raised-hand clips only while the lamp is lit.
	if is_torch_on and anim_override == &"" and not is_sitting and _sit <= 0.0:
		if anim == &"idle":
			anim = &"torch_idle"
		elif anim == &"walk":
			anim = &"torch_walk"
		elif anim == &"sprint":
			anim = &"torch_sprint"
	if _sprite.animation != anim:
		_sprite.play(anim)
	_sprite.speed_scale = clampf(rate, 0.3, 4.0)

	# No sit animation yet: lower and tilt the idle pose.
	_body.position.y = 0.0
	_body.rotation = 0.0
	_sit = move_toward(_sit, 1.0 if is_sitting else 0.0, delta * 1.2)
	if _sit > 0.0:
		var e: float = _sit * _sit * (3.0 - 2.0 * _sit)
		_body.position.y += 28.0 * e
		_body.rotation += -0.08 * e
	_body.modulate = _body.modulate.lerp(Color(0.6, 0.6, 0.65) if is_hidden else Color.WHITE, delta * 10.0)
	_update_lantern_attachment()


## Follow the rendered hand on every animation frame, including when facing left.
func _update_lantern_attachment() -> void:
	var raised: bool = is_torch_on and TORCH_HANDS.has(_sprite.animation)
	_lantern.visible = raised
	_lamp_glow.visible = raised
	if raised:
		var hands: Array = TORCH_HANDS[_sprite.animation]
		var point: Vector2 = hands[mini(_sprite.frame, hands.size() - 1)]
		_lantern.position = (point + _sprite.offset) * _sprite.scale
		_lamp_glow.position = _lantern.position + Vector2(48.0, 40.0) * _lantern.scale
		_torch_light.position = _visual.to_local(_body.to_global(_lamp_glow.position))
	else:
		_torch_light.position = Vector2(8, -67)
	if is_instance_valid(_light_area):
		_update_light_area()


## Cutscenes: walk to world-x with controls off; emits walk_arrived.
func walk_to(x: float) -> void:
	controls_enabled = false
	set_hidden(false)
	_auto_target_x = x


## Cutscenes: sit down (placeholder pose until the sit animation exists).
func sit() -> void:
	is_sitting = true
	velocity.x = 0.0


## Cutscenes: get back up from sitting.
func stand() -> void:
	is_sitting = false
