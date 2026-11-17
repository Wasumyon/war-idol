extends "res://minigames/tunnel/scripts/vent_lunger.gd"
## Footsteps wake this vent. Light shortens its exposed phase, never cancels the strike.
@export var hearing_range: float = 175.0
@export var warning_time: float = 0.65
@export var cooldown: float = 3.0
@export var strike_half_width: float = 48.0
## A faint visible rim for exposed vents in very dark rooms; this casts no gameplay light.
@export var readable_grate: bool = false
var _grate_highlight: Node2D

enum Phase { DORMANT, WARNING, EXPOSED, COOLDOWN }
var phase: Phase = Phase.DORMANT
var _timer: float = 0.0
var _exposed_time: float = 0.0
var _positions: Dictionary = {}
var _sound: AudioStreamPlayer2D
var _light_probe: Area2D
const KNOCK: AudioStream = preload("res://minigames/tunnel/art/sfx/vent_knock.wav")
const SNAP: AudioStream = preload("res://minigames/tunnel/art/sfx/worm_lunge.wav")


func _ready() -> void:
	super._ready()
	if readable_grate:
		_grate_highlight = Node2D.new()
		var mat: CanvasItemMaterial = CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_grate_highlight.material = mat
		_grate_highlight.draw.connect(_draw_grate_highlight)
		add_child(_grate_highlight)
	_sound = AudioStreamPlayer2D.new()
	_sound.max_distance = 850.0
	_sound.volume_db = -5.0
	add_child(_sound)
	_light_probe = Area2D.new()
	_light_probe.collision_layer = 0
	_light_probe.collision_mask = 4
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = hole_radius
	shape.shape = circle
	_light_probe.add_child(shape)
	add_child(_light_probe)


func _physics_process(delta: float) -> void:
	if _grate_highlight:
		_grate_highlight.queue_redraw()
	var heard: bool = false
	var nearby_guards: Array[EnemyGuard] = []
	var actors: Array[Node] = get_tree().get_nodes_in_group("player")
	actors.append_array(get_tree().get_nodes_in_group("guard"))
	for actor: Node in actors:
		if not actor is Node2D:
			continue
		var body: Node2D = actor as Node2D
		var previous: Vector2 = _positions.get(body.get_instance_id(), body.global_position)
		_positions[body.get_instance_id()] = body.global_position
		var near: bool = absf(body.global_position.x - global_position.x) < hearing_range \
				and absf(body.global_position.y - (global_position.y + 65.0)) < 100.0
		if body is Player and (body.is_dead or body.is_hidden):
			continue
		if near and body.global_position.distance_to(previous) > 0.2:
			heard = true
		if near and body is EnemyGuard:
			nearby_guards.append(body as EnemyGuard)
	if phase == Phase.DORMANT and heard:
		phase = Phase.WARNING
		_timer = warning_time
		knock()
		_play_sound(KNOCK)
	if phase == Phase.WARNING:
		for guard: EnemyGuard in nearby_guards:
			guard.hurry_past_vent(1.1)
		_timer -= delta
		if _timer <= 0.0:
			phase = Phase.EXPOSED
			_exposed_time = 0.0
			strike()
			_play_sound(SNAP)
	elif phase == Phase.EXPOSED:
		_exposed_time += delta
		# Allow the initial pop even in bright light, then pull back quickly.
		if _exposed_time > 0.16 and _illuminated():
			if _tween:
				_tween.kill()
			extension = move_toward(extension, 0.0, delta * 8.0)
			jaws = move_toward(jaws, 0.0, delta * 8.0)
		if extension > 0.65:
			for actor: Node in get_tree().get_nodes_in_group("player"):
				var player: Player = actor as Player
				if player and not player.is_hidden and not player.is_dead \
						and absf(player.global_position.x - global_position.x) < strike_half_width \
						and absf(player.global_position.y - (global_position.y + 65.0)) < 100.0:
					var side: float = -1.0 if player.global_position.x <= global_position.x else 1.0
					player.take_worm_hit(self, "It knocks before it strikes.\nI can wait outside its reach and\nmove when it pulls back.",
							global_position.x + side * (strike_half_width + 24.0))
		if _exposed_time > 0.2 and extension < 0.02:
			phase = Phase.COOLDOWN
			_timer = cooldown
	elif phase == Phase.COOLDOWN:
		_timer -= delta
		if _timer <= 0.0:
			phase = Phase.DORMANT


func _illuminated() -> bool:
	for area: Area2D in _light_probe.get_overlapping_areas():
		if area.is_in_group("light_source") and area.monitorable:
			return true
	return false


func _play_sound(stream: AudioStream) -> void:
	_sound.stream = stream
	_sound.play()


func _draw_grate_highlight() -> void:
	var shake: Vector2 = Vector2(sin(_time * 70.0), cos(_time * 63.0)) * rattle * 4.0
	draw_highlight_ring(shake)
	var bent: float = clampf(extension * 3.0, 0.0, 1.0)
	for i: int in 3:
		var y: float = (float(i) - 1.0) * hole_radius * 0.55
		var half: float = sqrt(maxf(hole_radius * hole_radius - y * y, 0.0))
		var middle: Vector2 = shake + Vector2(0, y - (3.0 + bent * 7.0) * (1.0 - absf(float(i) - 1.0) * 0.5))
		_grate_highlight.draw_polyline(PackedVector2Array([shake + Vector2(-half, y), middle, shake + Vector2(half, y)]), Color(0.24, 0.22, 0.19), 2.0, true)


func draw_highlight_ring(centre: Vector2) -> void:
	_grate_highlight.draw_circle(centre, hole_radius + 7.0, Color(0.105, 0.10, 0.09))
	_grate_highlight.draw_circle(centre, hole_radius, Color(0.018, 0.016, 0.015))
	_grate_highlight.draw_arc(centre, hole_radius + 4.0, 0.0, TAU, 32, Color(0.26, 0.235, 0.19), 3.0, true)
	_grate_highlight.draw_arc(centre, hole_radius + 5.0, PI, TAU, 16, Color(0.35, 0.30, 0.22), 1.5, true)
