class_name EndingSequence
extends Area2D
## Chamber 5: when he walks in, controls drop away, he walks slowly to the
## furnace and stands by it. Home free... then banging in the vent. He turns and
## shines his lamp at it, the grille bursts off, and instead of a monster
## Chip drops out. Fade to the ending CG with text beside it (Enter / Space /
## E advances), then a closing card. Enter restarts from Chamber 1.
## Node origin = on the floor line where the trigger sits.

@export var sit_x: float = 1250.0
@export var furnace_light_path: NodePath
## The vent: a Node2D at the vent opening with a child "Grille" (Polygon2D).
@export var vent_path: NodePath
@export var camera_path: NodePath
@export var cg_texture: Texture2D = preload("res://minigames/tunnel/art/cg/chip saved reveal.png")
## Chip's poses: two frames each, alternated to fake movement. All face right
## (toward where he sits). Bottom centre of each texture = on the floor.
@export_group("Chip")
@export var chip_tumble: Array[Texture2D] = [preload("res://minigames/tunnel/art/sprites/chip/chip_tumble_1.png"), preload("res://minigames/tunnel/art/sprites/chip/chip_tumble_2.png")]
@export var chip_dazed: Array[Texture2D] = [preload("res://minigames/tunnel/art/sprites/chip/chip_sit_dazed_1.png"), preload("res://minigames/tunnel/art/sprites/chip/chip_sit_dazed_2.png")]
@export var chip_rub: Array[Texture2D] = [preload("res://minigames/tunnel/art/sprites/chip/chip_sit_rub_1.png"), preload("res://minigames/tunnel/art/sprites/chip/chip_sit_rub_2.png")]
@export var chip_knees: Array[Texture2D] = [preload("res://minigames/tunnel/art/sprites/chip/chip_knees_1.png"), preload("res://minigames/tunnel/art/sprites/chip/chip_knees_2.png")]
@export var chip_scale: float = 0.5
## How far (world px) her poses sink into the floor so they touch it rather than
## rest on its top edge.
@export var chip_floor_sink: float = 6.0
## Extra sink for the dazed pose: its lowest pixels are only her hands and heels,
## so without this her body hovers above the floor.
@export var chip_dazed_sink: float = 9.0
@export var chip_dazed_time: float = 1.0
@export var chip_rub_time: float = 1.4
@export_group("")
## Where Chip lands (world-x), under the vent.
@export var chip_land_x: float = 1080.0

@export_group("Timing")
@export var settle_time: float = 2.0
@export var bang_gaps: PackedFloat32Array = PackedFloat32Array([0.0, 0.8, 0.5])
@export var silence_time: float = 0.6
@export var chip_hold: float = 1.6

@export_group("Text")
## Shown beside the CG as a dialogue log: each press of Space / Enter adds the
## next line under the earlier ones. "Name: text" puts the name above the line.
@export_multiline var cg_lines: PackedStringArray = PackedStringArray([
	"Phoroneus: C-Chip!",
	"Chip: Aww, I knew I'd find you~",
	"Phoroneus: You idiot! Who just walks into a hole?",
	"Chip: Dehe~",
	"Phoroneus: ... Let's just get the hell out of here.",
	"Chip: OH! About that, I found something interesting! Come with me...",
])
@export_multiline var closing_text: String = "WAR IDOLS - ESCAPED\n\nTO BE CONTINUED..."
@export_file("*.tscn") var restart_scene: String = "res://minigames/tunnel/scenes/chambers/chamber_1.tscn"

signal _advance

var _started: bool = false
var _waiting_input: bool = false
var _can_restart: bool = false
var _player: Player
var _vent: Node2D
var _camera: Camera2D
var _shake: float = 0.0
var _chip: Node2D
var _chip_spr: Sprite2D
var _chip_frames: Array[Texture2D] = []
var _chip_frame_time: float = 0.2
var _chip_frame_t: float = 0.0
var _chip_frame_i: int = 0
var _chip_pose_sink: float = 0.0
## Current pose name ("tumble", "dazed", "rub", "knees"), for tests.
var chip_pose: String = ""
var _layer: CanvasLayer
var _black: ColorRect
var _cg: TextureRect
var _text: Label  # body of the newest dialogue line
var _log: VBoxContainer
var _hint: Label
var _card: Label
var _prompt: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b10  # player
	body_entered.connect(_on_body_entered)
	_vent = get_node_or_null(vent_path) as Node2D
	_camera = get_node_or_null(camera_path) as Camera2D
	_build_overlay()


func _process(delta: float) -> void:
	if _chip_spr and _chip_frames.size() > 1:
		_chip_frame_t += delta
		if _chip_frame_t >= _chip_frame_time:
			_chip_frame_t = 0.0
			_chip_frame_i = (_chip_frame_i + 1) % _chip_frames.size()
			_show_chip_frame()
	if _camera:
		_shake = move_toward(_shake, 0.0, delta * 30.0)
		_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


func _on_body_entered(body: Node2D) -> void:
	if _started or not (body is Player):
		return
	_started = true
	_player = body as Player
	_run()


func _run() -> void:
	var p: Player = _player
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_hint"):
		hud.call("set_hint", "")
	# --- home free
	p.set_torch(false)
	p.walk_to(sit_x)
	await p.walk_arrived
	p.facing = 1  # stands by the fire, warming up
	var fl: PointLight2D = get_node_or_null(furnace_light_path) as PointLight2D
	if fl:
		create_tween().tween_property(fl, "energy", fl.energy * 1.5, settle_time)
	await _wait(settle_time)

	# --- banging in the vent
	for i: int in bang_gaps.size():
		await _wait(bang_gaps[i])
		_bang(i)
		if i == 0:
			await _wait(0.35)
			p.facing = 1 if _vent and _vent.global_position.x > p.global_position.x else -1
		if i == 1:
			p.set_torch(true)  # he reaches for the light
	await _wait(silence_time)

	# --- the grille bursts off; Chip drops out
	_burst_grille()
	await _wait(0.5)
	await _drop_chip()
	await _wait(chip_hold)

	# --- the reveal
	await _fade(_black, 1.0, 1.4)
	_cg.visible = true
	await _fade(_cg, 1.0, 1.2)
	_log.visible = true
	for line: String in cg_lines:
		var entry: Control = _add_line(line)
		await _fade(entry, 1.0, 0.6)
		_hint.visible = true
		_hint.modulate.a = 0.6
		await _wait_for_advance()
		_hint.visible = false
	var out: Tween = create_tween().set_parallel(true)
	out.tween_property(_log, "modulate:a", 0.0, 1.2)
	out.tween_property(_cg, "modulate:a", 0.0, 1.2)
	await out.finished
	_cg.visible = false
	_log.visible = false
	_card.visible = true
	await _fade(_card, 1.0, 1.2)
	await _wait(1.0)
	_prompt.visible = true
	await _fade(_prompt, 1.0, 0.8)
	_can_restart = true


func _bang(i: int) -> void:
	_shake = 6.0 + 3.0 * i
	if _vent == null:
		return
	var grille: Node2D = _vent.get_node_or_null("Grille") as Node2D
	if grille:
		var tw: Tween = create_tween()
		tw.tween_property(grille, "position", Vector2(randf_range(-4, 4), 3.0 + i), 0.05)
		tw.tween_property(grille, "position", Vector2.ZERO, 0.25)
	_pop_text("BANG", _vent.global_position + Vector2(randf_range(-40, 40), -40), 26 + 6 * i)
	# dust falling from the vent
	for k: int in 6:
		var d: Polygon2D = Polygon2D.new()
		d.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
		d.color = Color(0.6, 0.55, 0.5, 0.8)
		d.z_index = 4
		get_parent().add_child(d)
		d.global_position = _vent.global_position + Vector2(randf_range(-50, 50), 20)
		var tw2: Tween = d.create_tween()
		tw2.tween_property(d, "global_position:y", 0.0, randf_range(0.8, 1.4))
		tw2.parallel().tween_property(d, "modulate:a", 0.0, 1.4)
		tw2.tween_callback(d.queue_free)


func _burst_grille() -> void:
	_shake = 14.0
	if _vent == null:
		return
	var grille: Node2D = _vent.get_node_or_null("Grille") as Node2D
	_pop_text("CLANG", _vent.global_position + Vector2(0, -50), 40)
	if grille:
		var tw: Tween = create_tween()
		var land: Vector2 = Vector2(randf_range(-160, -90), -_vent.global_position.y - 6)
		tw.tween_property(grille, "position", land, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(grille, "rotation", -2.6, 0.55)


## Chip tumbles out of the vent, lands on her bum, rubs her head, gets onto
## her knees, looks around, and notices him. She stays kneeling (as in the CG).
func _drop_chip() -> void:
	_chip = Node2D.new()
	_chip.name = "Chip"
	_chip.z_index = 1
	get_parent().add_child(_chip)
	var has_art: bool = not chip_tumble.is_empty()
	if has_art:
		_chip_spr = Sprite2D.new()
		_chip_spr.centered = false
		_chip_spr.scale = Vector2.ONE * chip_scale
		_chip.add_child(_chip_spr)
		_set_chip_pose("tumble", chip_tumble, 0.08)
	else:
		_build_placeholder_chip(_chip)
	var start: Vector2 = _vent.global_position + Vector2(0, 40) if _vent else Vector2(chip_land_x, -300)
	_chip.global_position = start
	# --- tumble out and fall, spinning a little
	var tw: Tween = create_tween()
	tw.tween_property(_chip, "global_position:y", start.y + 12, 0.15)
	tw.tween_property(_chip, "global_position", Vector2(chip_land_x, 0), 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	var spin: Tween = create_tween()
	spin.tween_property(_chip, "rotation", 0.35, 0.3)
	spin.tween_property(_chip, "rotation", 0.0, 0.25)
	await tw.finished
	# --- THUMP: on her bum
	_chip.rotation = 0.0
	if has_art:
		_set_chip_pose("dazed", chip_dazed, 0.35)
	_shake = 5.0
	_dust_puff(_chip.global_position, 10, 70.0)
	_pop_text("THUMP", _chip.global_position + Vector2(0, -70), 24)
	var sq: Tween = create_tween()
	sq.tween_property(_chip, "scale", Vector2(1.2, 0.8), 0.06)
	sq.tween_property(_chip, "scale", Vector2.ONE, 0.2)
	if _player:
		_player.facing = 1 if chip_land_x > _player.global_position.x else -1
	if not has_art:
		await _wait(0.3)
		return
	await _wait(chip_dazed_time)
	# --- ow
	_set_chip_pose("rub", chip_rub, 0.2)
	_pop_text("ow...", _chip.global_position + Vector2(10, -80), 16)
	await _wait(chip_rub_time)
	# --- onto her knees
	_set_chip_pose("knees", chip_knees, 0.6)
	_dust_puff(_chip.global_position, 5, 40.0)
	var up: Tween = create_tween()
	up.tween_property(_chip, "position:y", -6.0, 0.1).as_relative()
	up.tween_property(_chip, "position:y", 6.0, 0.12).as_relative()
	await _wait(0.6)
	# --- looks away (left), then back toward him (right)
	_chip_spr.flip_h = true
	await _wait(0.7)
	_chip_spr.flip_h = false
	await _wait(0.45)
	# --- notices him
	_pop_text("!", _chip.global_position + Vector2(8, -100), 34)
	var hop: Tween = create_tween()
	hop.tween_property(_chip, "position:y", -12.0, 0.12).as_relative()
	hop.tween_property(_chip, "position:y", 12.0, 0.14).as_relative()
	await hop.finished


func _set_chip_pose(pose: String, frames: Array[Texture2D], frame_time: float) -> void:
	chip_pose = pose
	_chip_pose_sink = chip_dazed_sink if pose == "dazed" else 0.0
	_chip_frames = frames
	_chip_frame_time = frame_time
	_chip_frame_t = 0.0
	_chip_frame_i = 0
	_show_chip_frame()


## Bottom centre of the texture sits on the Chip node (the floor once landed).
func _show_chip_frame() -> void:
	if _chip_spr == null or _chip_frames.is_empty():
		return
	var tex: Texture2D = _chip_frames[_chip_frame_i]
	_chip_spr.texture = tex
	_chip_spr.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height() + (chip_floor_sink + _chip_pose_sink) / chip_scale)


func _dust_puff(at: Vector2, count: int, spread: float) -> void:
	for k: int in count:
		var d: Polygon2D = Polygon2D.new()
		d.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
		d.color = Color(0.6, 0.55, 0.5, 0.8)
		d.z_index = 2
		get_parent().add_child(d)
		d.global_position = at + Vector2(randf_range(-10, 10), -3)
		var dir: float = -1.0 if k % 2 == 0 else 1.0
		var tw: Tween = d.create_tween().set_parallel(true)
		tw.tween_property(d, "global_position", at + Vector2(dir * randf_range(spread * 0.4, spread), -randf_range(6, 22)), 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "modulate:a", 0.0, 0.6)
		tw.chain().tween_callback(d.queue_free)


## A small, round, unmistakably-not-a-monster placeholder for Chip.
func _build_placeholder_chip(root: Node2D) -> void:
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_NORMAL
	var body: Polygon2D = Polygon2D.new()
	body.color = Color(0.55, 0.62, 0.7)
	body.polygon = _ellipse(Vector2(0, -26), 20, 26)
	root.add_child(body)
	var head: Polygon2D = Polygon2D.new()
	head.color = Color(0.62, 0.68, 0.76)
	head.polygon = _ellipse(Vector2(0, -62), 17, 15)
	root.add_child(head)
	var glow: CanvasItemMaterial = CanvasItemMaterial.new()
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for ex: float in [-6.0, 6.0]:
		var eye: Polygon2D = Polygon2D.new()
		eye.material = glow
		eye.color = Color(0.6, 0.95, 1.0)
		eye.polygon = _ellipse(Vector2(ex, -63), 3, 4)
		root.add_child(eye)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		var a: float = TAU * float(i) / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _pop_text(word: String, at: Vector2, size: int) -> void:
	var l: Label = Label.new()
	l.text = word
	l.z_index = 6
	var m: CanvasItemMaterial = CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	l.material = m
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.55))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	get_parent().add_child(l)
	l.global_position = at - Vector2(size * 1.2, 0)
	var tw: Tween = l.create_tween()
	tw.tween_property(l, "global_position:y", at.y - 50, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


func _wait(sec: float) -> void:
	if sec > 0.0:
		await get_tree().create_timer(sec).timeout


func _wait_for_advance() -> void:
	_waiting_input = true
	await _advance


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	if not pressed:
		return
	if _waiting_input:
		_waiting_input = false
		_advance.emit()
	elif _can_restart:
		_can_restart = false
		GameManager.go_to_chamber(restart_scene)


## Tests and skip: advance the current text line.
func advance() -> void:
	if _waiting_input:
		_waiting_input = false
		_advance.emit()


func _fade(node: CanvasItem, to: float, time: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", to, time)
	await tw.finished


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.modulate.a = 0.0
	root.add_child(_black)
	# CG on the left half, text on the right.
	_cg = TextureRect.new()
	_cg.texture = cg_texture
	_cg.anchor_left = 0.04
	_cg.anchor_right = 0.5
	_cg.anchor_top = 0.04
	_cg.anchor_bottom = 0.96
	_cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cg.modulate.a = 0.0
	_cg.visible = false
	root.add_child(_cg)
	# Dialogue log on the right: lines stack top-down as the player advances.
	_log = VBoxContainer.new()
	_log.anchor_left = 0.54
	_log.anchor_right = 0.94
	_log.anchor_top = 0.08
	_log.anchor_bottom = 0.84
	_log.alignment = BoxContainer.ALIGNMENT_BEGIN
	_log.add_theme_constant_override("separation", 22)
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.visible = false
	root.add_child(_log)
	_hint = Label.new()
	_hint.text = "SPACE"
	_hint.anchor_left = 0.54
	_hint.anchor_right = 0.94
	_hint.anchor_top = 0.88
	_hint.anchor_bottom = 0.93
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color(0.93, 0.78, 0.5))
	_hint.visible = false
	root.add_child(_hint)
	_card = _make_label(root, closing_text, 34, Color(0.93, 0.78, 0.5))
	_prompt = _make_label(root, "\n\n\n\n\n\n\nENTER   play again", 18, Color(0.93, 0.78, 0.5, 0.7))


## Adds one dialogue line under the earlier ones (which dim) and returns it,
## transparent, ready to fade in.
func _add_line(line: String) -> Control:
	for old: Node in _log.get_children():
		(old as Control).modulate.a = 0.5
	var speaker: String = ""
	var body: String = line
	var colon: int = line.find(": ")
	if colon > 0 and colon < 20:
		speaker = line.substr(0, colon)
		body = line.substr(colon + 2)
	var entry: VBoxContainer = VBoxContainer.new()
	entry.add_theme_constant_override("separation", 2)
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if speaker != "":
		var name_l: Label = Label.new()
		name_l.text = speaker.to_upper()
		name_l.add_theme_font_size_override("font_size", 15)
		name_l.add_theme_color_override("font_color", _speaker_color(speaker))
		entry.add_child(name_l)
	_text = Label.new()
	_text.text = body
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 23)
	_text.add_theme_color_override("font_color", Color(0.93, 0.87, 0.76))
	entry.add_child(_text)
	entry.modulate.a = 0.0
	_log.add_child(entry)
	return entry


func _speaker_color(speaker: String) -> Color:
	match speaker.to_lower():
		"chip":
			return Color(1.0, 0.5, 0.72)
		_:
			return Color(0.93, 0.68, 0.38)


func _make_label(root: Control, text: String, size: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.modulate.a = 0.0
	l.visible = false
	root.add_child(l)
	return l
