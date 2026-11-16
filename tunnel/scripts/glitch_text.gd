class_name GlitchText
extends Control
## Garbled, glitchy speech text. Characters arrive scrambled and resolve one
## by one; once resolved the line keeps flickering: a random glyph swap, a
## sideways jitter, and red / cyan ghost copies that split apart now and then.
## Works in the world (child of a guard, unshaded so the darkness doesn't eat
## it) and in UI layers.

const GLYPHS: String = "#%&@$!?/\\|<>*=+~^01ØÆ¥§"

@export var font_size: int = 26
@export var color: Color = Color(1.0, 0.86, 0.7)
## Seconds per character to resolve.
@export var resolve_time: float = 0.03
## Chance per frame of a glitch once the line is resolved.
@export var glitch_chance: float = 0.06

var text: String = ""
## If set, the text sits at follow + follow_offset in world space (use with
## GlitchText.make_world_speech so the darkness doesn't dim it).
var follow: Node2D
var follow_offset: Vector2 = Vector2.ZERO
var _shown: float = 0.0
var _life: float = 0.0
var _hold: float = 0.0
var _glitch_frames: int = 0
var _main: Label
var _red: Label
var _cyan: Label


## Speech above a world node, drawn on its own screen layer (positioned over
## the node every frame) so the chamber's CanvasModulate darkness doesn't dim it.
static func make_world_speech(owner: Node2D, offset: Vector2) -> GlitchText:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "SpeechLayer"
	layer.layer = 11  # a screen layer above the HUD vignette; the darkness doesn't reach it
	owner.add_child(layer)
	var g: GlitchText = GlitchText.new()
	g.name = "Speech"
	g.follow = owner
	g.follow_offset = offset
	layer.add_child(g)
	return g


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_red = _make_label(Color(1.0, 0.15, 0.2, 0.55))
	_cyan = _make_label(Color(0.2, 0.9, 1.0, 0.45))
	_main = _make_label(color)
	visible = false


## Show a line for `hold` seconds (after it has resolved), then fade out.
## hold < 0 keeps it up until hide_text().
func say(line: String, hold: float = 1.6) -> void:
	text = line
	_shown = 0.0
	_life = 0.0
	_hold = hold
	modulate.a = 1.0
	visible = true


func hide_text() -> void:
	visible = false
	text = ""


func _make_label(c: Color) -> Label:
	var l: Label = Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, c.a))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.size = Vector2(900, 40)
	l.position = Vector2(-450, -20)
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	l.material = mat
	add_child(l)
	return l


func _process(delta: float) -> void:
	if follow and is_instance_valid(follow):
		# World -> screen, so it rides above him as the camera moves.
		position = follow.get_viewport().get_canvas_transform() * (follow.global_position + follow_offset)
		scale = follow.get_viewport().get_canvas_transform().get_scale()
	if not visible or text == "":
		return
	_life += delta
	_shown = minf(_shown + delta / resolve_time, float(text.length()))
	var resolved: int = int(_shown)

	if resolved >= text.length() and _glitch_frames <= 0 and randf() < glitch_chance:
		_glitch_frames = randi_range(2, 5)
	var glitching: bool = _glitch_frames > 0
	_glitch_frames -= 1

	var out: String = ""
	for i: int in text.length():
		var ch: String = text[i]
		if ch == " ":
			out += " "
		elif i >= resolved or (glitching and randf() < 0.25):
			out += GLYPHS[randi() % GLYPHS.length()]
		else:
			out += ch
	# Not yet resolved part shows only up to a scrambled cursor.
	if resolved < text.length():
		out = out.substr(0, resolved + 1)
	_main.text = out
	_red.text = out
	_cyan.text = out

	var split: float = 6.0 if glitching else 1.5
	var jitter: float = randf_range(-3.0, 3.0) if glitching else 0.0
	_main.position = Vector2(-450 + jitter, -20)
	_red.position = Vector2(-450 - split + jitter, -20 + (1.0 if glitching else 0.0))
	_cyan.position = Vector2(-450 + split + jitter, -20 - (1.0 if glitching else 0.0))
	_red.visible = glitching or randf() < 0.5
	_cyan.visible = glitching or randf() < 0.5

	if _hold >= 0.0 and resolved >= text.length():
		var t: float = _life - text.length() * resolve_time
		if t > _hold:
			modulate.a = maxf(1.0 - (t - _hold) / 0.4, 0.0)
			if modulate.a <= 0.0:
				hide_text()
