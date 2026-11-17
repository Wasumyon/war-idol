extends Node2D
## Room 0: the fall. He drops down the vent shaft with controls off. Vent worms knock in
## the walls ahead of him and strike just behind him: he falls faster than they can reach.
## He lands in the dark, gets up, and the player turns on the lamp. No guards, no danger.

@export var player_path: NodePath = ^"Player"
@export var camera_path: NodePath = ^"MainCamera"
## Terminal speed in the shaft (px/s): sets how long the fall lasts.
@export var fall_speed: float = 950.0
@export var start_fall_speed: float = 500.0
## Time left in the drop when he lowers his feet to brace for the floor at y = 0.
const BRACE_TIME: float = 0.34
const RECOVERY_TIME: float = 0.4
const IMPACT_DURATION: float = 0.42
const LANDING_LINE: String = "Nothing broken… A miracle.\nDamn dark down here though.\nWhere’s my light…"
## A worm cluster knocks when he is this far above it, and strikes once he is this far below it.
@export var knock_lead: float = 520.0
@export var strike_lag: float = 95.0
## Back-wall lungers (VentLunger): knock and lunge at the camera on the same idea, a touch later.
@export var lunger_knock_lead: float = 600.0
@export var lunger_strike_lag: float = 70.0
## Seconds between hitting the floor and giving control back.
@export var get_up_delay: float = 1.3

var _player: Player
var _camera: Camera2D
var _worms: Array[TubewormCluster] = []
## Per worm: 0 = waiting, 1 = knocked, 2 = struck.
var _state: Array[int] = []
var _lungers: Array[VentLunger] = []
var _lunger_state: Array[int] = []
var _falling: bool = true
var _shake: float = 0.0
var _impact_left: float = 0.0
var _sfx: Dictionary = {}
var _presence: PointLight2D
var _presence_energy: float = 0.0
## While falling his faint presence glow is brighter, so you can follow him down the shaft.
@export var fall_presence_energy: float = 0.85


func _ready() -> void:
	_player = get_node(player_path) as Player
	_camera = get_node(camera_path) as Camera2D
	_player.controls_enabled = false
	_player.max_fall_speed = fall_speed
	_player.velocity.y = start_fall_speed
	_player.facing = 1
	_player.anim_override = &"fall"
	for n: Node in get_tree().get_nodes_in_group("vent_worms"):
		var w: TubewormCluster = n as TubewormCluster
		w.growth = 0.0
		w.visible = false
		_worms.append(w)
	_worms.sort_custom(func(a: TubewormCluster, b: TubewormCluster) -> bool:
		return a.global_position.y < b.global_position.y)
	_state.resize(_worms.size())
	_state.fill(0)
	for n: Node in get_tree().get_nodes_in_group("vent_lungers"):
		_lungers.append(n as VentLunger)
	_lungers.sort_custom(func(a: VentLunger, b: VentLunger) -> bool:
		return a.global_position.y < b.global_position.y)
	_lunger_state.resize(_lungers.size())
	_lunger_state.fill(0)
	for s: String in ["vent_knock", "worm_strike", "worm_lunge", "land_thud", "lamp_click"]:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.stream = load("res://minigames/tunnel/art/sfx/%s.wav" % s)
		add_child(p)
		_sfx[s] = p
	_player.torch_toggled.connect(_on_torch_toggled)
	_presence = _player.get_node("PresenceLight") as PointLight2D
	_presence_energy = _presence.energy
	_presence.energy = fall_presence_energy


func _physics_process(delta: float) -> void:
	var py: float = _player.global_position.y
	for i: int in _worms.size():
		var w: TubewormCluster = _worms[i]
		# 0..1 down the shaft: the knocking gets louder and the strikes harder as he falls.
		var depth: float = float(i) / maxf(_worms.size() - 1, 1)
		if _state[i] == 0 and py > w.global_position.y - knock_lead:
			_state[i] = 1
			_knock(w, depth)
		elif _state[i] == 1 and py > w.global_position.y + strike_lag:
			_state[i] = 2
			_strike(w, depth)

	for i: int in _lungers.size():
		var l: VentLunger = _lungers[i]
		var depth: float = float(i) / maxf(_lungers.size() - 1, 1)
		if _lunger_state[i] == 0 and py > l.global_position.y - lunger_knock_lead:
			_lunger_state[i] = 1
			# deeper and duller than the side worms: it's behind the back wall
			_play("vent_knock", lerpf(-10.0, 0.0, depth), randf_range(0.6, 0.7))
			_shake = maxf(_shake, lerpf(3.0, 8.0, depth))
			l.knock(depth)
		elif _lunger_state[i] == 1 and py > l.global_position.y + lunger_strike_lag:
			_lunger_state[i] = 2
			_play("worm_lunge", lerpf(-10.0, -4.0, depth), randf_range(0.95, 1.08))
			_shake = maxf(_shake, lerpf(4.0, 8.0, depth))
			l.strike()

	if _falling:
		if _player.is_on_floor():
			_falling = false
			_land()
		elif py >= -fall_speed * BRACE_TIME:
			_player.anim_override = &"fall_brace"

	_shake = move_toward(_shake, 0.0, delta * 40.0)
	if _impact_left > 0.0:
		var progress: float = 1.0 - _impact_left / IMPACT_DURATION
		var strength: float = (1.0 - progress) * (1.0 - progress)
		_camera.offset = Vector2(sin(progress * TAU * 3.0) * 9.0,
				cos(progress * TAU * 2.5) * 34.0) * strength
		_impact_left = maxf(_impact_left - delta, 0.0)
	else:
		_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


## Something thumps inside the duct wall ahead of him; the plumes peek out of the crack.
func _knock(w: TubewormCluster, depth: float) -> void:
	w.visible = true
	_play("vent_knock", lerpf(-14.0, -1.0, depth), randf_range(0.9, 1.1))
	_shake = maxf(_shake, lerpf(2.0, 7.0, depth))
	var t: Tween = create_tween()
	t.tween_property(w, "growth", 0.12, 0.08)
	t.tween_property(w, "growth", 0.0, 0.18)
	t.tween_interval(0.12)
	t.tween_property(w, "growth", 0.16, 0.07)
	t.tween_property(w, "growth", 0.03, 0.2)
	_dust(w.global_position, w.rotation, 5)


## The worms lunge out of the wall, but he's already past them.
func _strike(w: TubewormCluster, depth: float) -> void:
	_play("worm_strike", lerpf(-8.0, 0.0, depth), randf_range(0.85, 1.15))
	_shake = maxf(_shake, lerpf(5.0, 11.0, depth))
	var t: Tween = create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(w, "growth", 1.0, 0.16)
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(w, "growth", 0.7, 1.2)
	_dust(w.global_position, w.rotation, 9)


func _land() -> void:
	_player.freeze()
	_player.anim_override = &"hide"
	_play("land_thud", 4.0, 0.91)
	_impact_left = IMPACT_DURATION
	_shake = 0.0
	_dust(_player.global_position, 0.0, 24)
	# Landed in the dark: his glow fades back to almost nothing.
	create_tween().tween_property(_presence, "energy", _presence_energy, 1.0)
	var crouch_time: float = maxf(get_up_delay - RECOVERY_TIME, 0.0)
	var breath: float = minf(0.55, crouch_time)
	await get_tree().create_timer(breath, false).timeout
	_player.speak(LANDING_LINE, 4.0, Vector2(24, -318))
	await get_tree().create_timer(crouch_time - breath, false).timeout
	_player.anim_override = &"fall_recover"
	await get_tree().create_timer(RECOVERY_TIME, false).timeout
	_player.anim_override = &""
	_player.max_fall_speed = 100000.0
	_player.controls_enabled = true


func _on_torch_toggled(is_on: bool) -> void:
	_play("lamp_click", -6.0, 1.0 if is_on else 0.85)


func _play(sfx: String, volume_db: float, pitch: float) -> void:
	var p: AudioStreamPlayer = _sfx[sfx]
	p.volume_db = volume_db if sfx == "lamp_click" else volume_db - 4.0
	p.pitch_scale = pitch
	p.play()


## A one-shot puff of grit. `angle` is the worm cluster's rotation (its "up" points into the shaft).
func _dust(pos: Vector2, angle: float, amount: int) -> void:
	var d: CPUParticles2D = CPUParticles2D.new()
	d.one_shot = true
	d.emitting = false
	d.amount = amount
	d.lifetime = 0.9
	d.explosiveness = 0.95
	d.direction = Vector2.UP.rotated(angle)
	d.spread = 50.0
	d.initial_velocity_min = 60.0
	d.initial_velocity_max = 170.0
	d.gravity = Vector2(0, 420)
	d.scale_amount_min = 2.0
	d.scale_amount_max = 4.0
	d.color = Color(0.55, 0.5, 0.45, 0.8)
	d.z_index = 4
	d.global_position = pos
	add_child(d)
	d.emitting = true
	get_tree().create_timer(1.5).timeout.connect(d.queue_free)
