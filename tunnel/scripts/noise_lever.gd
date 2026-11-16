class_name NoiseLever
extends Area2D
## A switchboard wired to a remote sounder. Press E nearby to trigger
## an electronic pop at noise_x, where guards go to investigate.
## Node origin = on the floor line at the valve.

@export var noise_x: float = 2450.0
## Seconds before it can be banged again.
@export var cooldown: float = 6.0
@export var pipe_y: float = -330.0
## Raise the panel above a vent and keep it readable on a dark pillar face.
@export var panel_offset_y: float = 0.0
@export var panel_readable: bool = false

var _player_here: bool = false
var _cool: float = 0.0
var _clang: Label
var _indicator: Polygon2D
var _sound: AudioStreamPlayer2D
var _prompt: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b10  # player
	body_entered.connect(func(b: Node2D) -> void: if b is Player: _player_here = true)
	body_exited.connect(func(b: Node2D) -> void: if b is Player: _player_here = false)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(90, 200)
	shape.shape = rect
	shape.position = Vector2(0, -100)
	add_child(shape)
	_build()


func _physics_process(delta: float) -> void:
	_cool = maxf(_cool - delta, 0.0)
	_indicator.color = Color(0.7, 0.28, 0.12) if _cool > 0.0 else Color(0.35, 0.65, 0.45)
	var p: Player = get_tree().get_first_node_in_group("player") as Player
	var usable: bool = _player_here and _cool <= 0.0 and p != null
	if p != null:
		usable = usable and not p.is_dead and not p.is_hidden and p.controls_enabled
	_prompt.modulate.a = move_toward(_prompt.modulate.a, 0.55 if usable else 0.0, delta * 4.0)
	if not _player_here or _cool > 0.0:
		return
	if p == null or p.is_dead or p.is_hidden or not p.controls_enabled:
		return
	if Input.is_action_just_pressed("interact"):
		_bang()


func _bang() -> void:
	_cool = cooldown
	_prompt.modulate.a = 0.0
	_sound.play()
	for g: Node in get_tree().get_nodes_in_group("guard"):
		if g.has_method("hear_noise"):
			g.call("hear_noise", noise_x)
	_clang.modulate.a = 1.0
	_clang.position = Vector2(noise_x - global_position.x - 40, pipe_y - 60)
	var tw: Tween = create_tween()
	tw.tween_property(_clang, "position:y", pipe_y - 100, 1.2)
	tw.parallel().tween_property(_clang, "modulate:a", 0.0, 1.2)


func _build() -> void:
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# Cable runs from the switchboard to the remote sounder.
	var pipe: Line2D = Line2D.new()
	pipe.z_index = -5
	pipe.width = 3.0
	pipe.default_color = Color(0.36, 0.3, 0.24)
	pipe.points = PackedVector2Array([Vector2(0, -60 + panel_offset_y), Vector2(0, pipe_y), Vector2(noise_x - global_position.x, pipe_y), Vector2(noise_x - global_position.x, pipe_y + 40)])
	add_child(pipe)
	var sounder: Polygon2D = Polygon2D.new()
	sounder.position = Vector2(noise_x - global_position.x, pipe_y + 40)
	sounder.z_index = -4
	sounder.color = Color(0.34, 0.33, 0.29)
	sounder.polygon = PackedVector2Array([Vector2(-18, -12), Vector2(18, -12), Vector2(18, 12), Vector2(-18, 12)])
	add_child(sounder)
	for y: int in [-6, 0, 6]:
		var grille: Line2D = Line2D.new()
		grille.points = PackedVector2Array([Vector2(-11, y), Vector2(11, y)])
		grille.width = 2.0
		grille.default_color = Color(0.1, 0.11, 0.1)
		sounder.add_child(grille)
	var panel: Node2D = Node2D.new()
	panel.name = "SwitchPanel"
	panel.position.y = panel_offset_y
	panel.z_index = 2
	add_child(panel)
	var box: Polygon2D = Polygon2D.new()
	if panel_readable:
		box.material = unshaded
	box.color = Color(0.3, 0.26, 0.22)
	box.polygon = PackedVector2Array([Vector2(-23, -130), Vector2(23, -130), Vector2(23, -65), Vector2(-23, -65)])
	panel.add_child(box)
	var screen: Polygon2D = Polygon2D.new()
	screen.z_index = 1
	if panel_readable:
		screen.material = unshaded
	screen.color = Color(0.12, 0.2, 0.18)
	screen.polygon = PackedVector2Array([Vector2(-16, -122), Vector2(16, -122), Vector2(16, -100), Vector2(-16, -100)])
	panel.add_child(screen)
	_indicator = Polygon2D.new()
	_indicator.z_index = 1
	_indicator.material = unshaded
	_indicator.polygon = PackedVector2Array([Vector2(-14, -88), Vector2(-6, -88), Vector2(-6, -80), Vector2(-14, -80)])
	panel.add_child(_indicator)
	var button: Polygon2D = Polygon2D.new()
	button.z_index = 1
	if panel_readable:
		button.material = unshaded
	button.color = Color(0.6, 0.45, 0.28)
	button.polygon = PackedVector2Array([Vector2(3, -91), Vector2(15, -91), Vector2(15, -77), Vector2(3, -77)])
	panel.add_child(button)
	_sound = AudioStreamPlayer2D.new()
	_sound.position = Vector2(noise_x - global_position.x, pipe_y + 40)
	_sound.max_distance = 2400.0
	_sound.attenuation = 0.6
	_sound.volume_db = -4.0
	_sound.stream = _make_pop()
	add_child(_sound)
	_prompt = Label.new()
	_prompt.text = "E"
	_prompt.position = Vector2(-8, -155 + panel_offset_y)
	_prompt.z_index = 5
	_prompt.material = unshaded
	_prompt.add_theme_font_size_override("font_size", 16)
	_prompt.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.modulate.a = 0.0
	add_child(_prompt)
	_clang = Label.new()
	_clang.text = ""
	_clang.z_index = 5
	_clang.material = unshaded
	_clang.add_theme_font_size_override("font_size", 30)
	_clang.add_theme_color_override("font_color", Color(1, 0.8, 0.45))
	_clang.add_theme_color_override("font_outline_color", Color.BLACK)
	_clang.add_theme_constant_override("outline_size", 6)
	_clang.modulate.a = 0.0
	add_child(_clang)


## Short relay pop and descending electronic chirp, with two tunnel echoes.
func _make_pop() -> AudioStreamWAV:
	var rate: int = 22050
	var data: PackedByteArray = PackedByteArray()
	data.resize(rate * 2)
	for i: int in rate:
		var t: float = float(i) / rate
		var sample: float = 0.0
		for echo: int in 3:
			var u: float = t - float(echo) * 0.18
			if u < 0.0:
				continue
			var tone: float = sin(TAU * (820.0 * u - 350.0 * u * u)) * exp(-u * 24.0)
			var pop: float = (sin(u * 19301.0) + sin(u * 29731.0)) * exp(-u * 130.0) * 0.3
			sample += (tone * 0.5 + pop) * pow(0.32, echo) * minf(u * 1500.0, 1.0)
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 28000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
