extends Control
## The opening, before Chamber 0. Black screen: Phoroneus shouts through the
## ambush while explosions shake everything. The floor gives way and Chip falls
## (CG). Black again: you hear him back up, take a run-up and jump, and the game
## cuts into the Room 0 fall. Enter / Space / E skips; Esc pauses as usual.

@export var lines: PackedStringArray = PackedStringArray([
	"AMBUSH!",
	"Over there! The old bunker tunnels!",
	"WAIT, CHIP! NOT THAT WAY!",
])
@export var speaker: String = "Phoroneus"
@export var cg_texture: Texture2D = preload("res://minigames/tunnel/art/cg/fall_bg/chip_fall_yellow_red_1.png")
## Optional text over the jump ("You crouch." / "Then jump."); off = sound only.
@export var show_jump_text: bool = false
@export_file("*.tscn") var next_scene: String = "res://minigames/tunnel/scenes/chambers/chamber_0.tscn"

const SFX_BOOM: AudioStream = preload("res://minigames/tunnel/art/sfx/intro_boom.wav")
const SFX_RUMBLE: AudioStream = preload("res://minigames/tunnel/art/sfx/intro_rumble.wav")
const SFX_CRACK: AudioStream = preload("res://minigames/tunnel/art/sfx/intro_crack.wav")
const SFX_DEBRIS: AudioStream = preload("res://minigames/tunnel/art/sfx/intro_debris.wav")
const SFX_SCUFF: AudioStream = preload("res://minigames/tunnel/art/sfx/intro_scuff.wav")
const SFX_JUMP: AudioStream = preload("res://minigames/tunnel/art/sfx/intro_jump.wav")
const SFX_STEPS: Array[AudioStream] = [
	preload("res://minigames/tunnel/art/sfx/step_player_concrete_0.wav"),
	preload("res://minigames/tunnel/art/sfx/step_player_concrete_1.wav"),
	preload("res://minigames/tunnel/art/sfx/step_player_concrete_2.wav"),
]

## Set when the intro has ended (finished or skipped); stops the timeline.
var finished: bool = false
## Which beat the timeline is on (tests read this).
var beat: String = ""

var _stage: Control
var _flash: ColorRect
var _cg: TextureRect
var _name: Label
var _line: Label
var _skip_hint: Label
var _rumble: AudioStreamPlayer
var _trauma: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Everything that shakes lives on the stage.
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_stage)

	_cg = TextureRect.new()
	_cg.texture = cg_texture
	_cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cg.modulate.a = 0.0
	_stage.add_child(_cg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	_stage.add_child(box)
	_name = _label(box, speaker.to_upper(), 18, Color(0.93, 0.68, 0.38))
	_line = _label(box, "", 52, Color(0.96, 0.9, 0.8))
	_name.modulate.a = 0.0

	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.86, 0.6)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.modulate.a = 0.0
	add_child(_flash)

	_skip_hint = Label.new()
	_skip_hint.text = "ENTER  skip"
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(0.93, 0.78, 0.5))
	_skip_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.position += Vector2(-120, -40)
	_skip_hint.modulate.a = 0.0
	add_child(_skip_hint)

	_rumble = AudioStreamPlayer.new()
	_rumble.stream = SFX_RUMBLE
	_rumble.volume_db = -30.0
	add_child(_rumble)

	_run()


func _label(parent: Control, text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	parent.add_child(l)
	return l


func _process(delta: float) -> void:
	_trauma = maxf(0.0, _trauma - delta * 1.4)
	var s: float = _trauma * _trauma * 26.0
	_stage.position = Vector2(randf_range(-s, s), randf_range(-s, s))


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_finish()


## Pausable wait; returns true if the intro ended meanwhile.
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds, false).timeout
	return finished


func _sfx(stream: AudioStream, db: float = 0.0, pitch: float = 1.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db - 6.0
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _shout(text: String, hit: float) -> void:
	_name.modulate.a = 1.0
	_line.text = text
	_line.scale = Vector2.ONE
	_line.pivot_offset = _line.size * 0.5
	var tw := create_tween()
	_line.scale = Vector2(1.15, 1.15)
	tw.tween_property(_line, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	_trauma = minf(1.0, _trauma + hit)


func _explode(strength: float, db: float) -> void:
	_sfx(SFX_BOOM, db, randf_range(0.92, 1.05))
	_trauma = minf(1.0, _trauma + strength)
	_flash.modulate.a = 0.55 * strength
	create_tween().tween_property(_flash, "modulate:a", 0.0, 0.35)


func _run() -> void:
	beat = "black"
	_rumble.play()
	create_tween().tween_property(_rumble, "volume_db", -18.0, 1.0)
	create_tween().tween_property(_skip_hint, "modulate:a", 0.45, 1.0).set_delay(1.5)
	if await _wait(0.8): return

	beat = "line1"
	_explode(0.9, -2.0)
	_shout(lines[0], 0.3)
	if await _wait(1.9): return

	beat = "line2"
	_explode(0.45, -9.0)
	_shout(lines[1], 0.15)
	if await _wait(2.1): return

	beat = "line3"
	_sfx(SFX_CRACK, -2.0)
	_shout(lines[2], 0.6)
	if await _wait(1.3): return

	# The floor gives way: text cuts out, a beat of black, then she's falling.
	beat = "gap"
	_name.modulate.a = 0.0
	_line.text = ""
	_explode(0.7, -6.0)
	_sfx(SFX_DEBRIS, -3.0)
	if await _wait(0.45): return

	beat = "cg"
	_cg.modulate.a = 1.0
	_cg.pivot_offset = size * 0.5
	_cg.scale = Vector2(1.0, 1.0)
	_flash.modulate.a = 0.35
	create_tween().tween_property(_flash, "modulate:a", 0.0, 0.4)
	create_tween().tween_property(_cg, "scale", Vector2(1.07, 1.07), 4.0)
	if await _wait(3.4): return
	create_tween().tween_property(_cg, "modulate:a", 0.0, 0.6)
	create_tween().tween_property(_rumble, "volume_db", -40.0, 1.6)
	if await _wait(1.2): return

	# Black. He backs up, crouches, takes a run-up and jumps in after her.
	beat = "jump"
	_sfx(SFX_SCUFF, -6.0, 1.0)
	if show_jump_text:
		_line.add_theme_font_size_override("font_size", 30)
		_line.text = "You crouch."
	if await _wait(0.5): return
	_sfx(SFX_SCUFF, -7.0, 0.9)
	if await _wait(0.8): return
	if show_jump_text:
		_line.text = "Then jump."
	for gap: float in [0.30, 0.24, 0.20, 0.17]:
		_sfx(SFX_STEPS[randi() % SFX_STEPS.size()], -2.0, randf_range(1.0, 1.12))
		if await _wait(gap): return
	_line.text = ""
	_sfx(SFX_JUMP, -3.0)
	if await _wait(0.35): return
	_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	beat = "done"
	TunnelManager.i.go_to_chamber(next_scene)
