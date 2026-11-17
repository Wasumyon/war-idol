extends Node
## Autoload "GameManager": checkpoints, death/respawn and chamber transitions.
## Lives above every chamber scene, so its fade overlay and checkpoint survive scene reloads.

signal player_died
signal chamber_changed(scene_path: String)
signal respawn_hint(line: String)
signal lives_changed(remaining: int)

const FADE_TIME: float = 0.45
const MAX_LIVES: int = 3
const DEATH_HINT_THRESHOLD: int = 3
const GUARD_HINT: String = "I didn’t expect the Ministry down here.\nIf he sees me, I bet I can give him the slip\nif I get behind something…"
const GUARD_LAMP_HINT: String = "I think the bastard sees my light.\nI can give him the slip if I get\nbehind something…"

## Where the player reappears after dying in the current chamber.
var checkpoint: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false
var death_count: int = 0
var lives: int = MAX_LIVES
## Free-form story/puzzle flags, e.g. flags["has_lamp"] = true.
var flags: Dictionary = {}
var _hazard_deaths: Dictionary[String, int] = {}
## Playtest cheat on G: no deaths plus faster movement. Each press steps
## off -> 2.5x -> 5x -> off. Survives respawns and chamber changes.
const GOD_SPEEDS: Array[float] = [1.0, 2.5]
var god_level: int = 0
var god_mode: bool = false
## Speed multiplier the player uses (1.0 when god mode is off).
var god_speed_mult: float = 1.0
## God mode only: number keys 0-5 jump to the start of that chamber (if it exists).
const CHAMBER_PATH: String = "res://scenes/chambers/chamber_%d.tscn"

var _busy: bool = false
var _fade_rect: ColorRect
var _god_label: Label
## What the guard said when he got you: shown, glitched, over the black fade.
var _death_line: String = ""
var _death_caption: GlitchText
## Seconds the death line holds on black before the reload.
const DEATH_LINE_HOLD: float = 1.1


func _ready() -> void:
	# Keep fading even if a chamber pauses the tree.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)

	_god_label = Label.new()
	_god_label.text = "GOD MODE"
	_god_label.position = Vector2(16, 12)
	_god_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_god_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_god_label.add_theme_constant_override("outline_size", 4)
	_god_label.visible = false
	layer.add_child(_god_label)

	_death_caption = GlitchText.new()
	_death_caption.font_size = 30
	_death_caption.set_anchors_preset(Control.PRESET_CENTER)
	layer.add_child(_death_caption)

	# Start the game on black and fade in.
	_fade_rect.modulate.a = 1.0
	_fade(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	# Debug / jam convenience: R restarts the chamber from the last checkpoint.
	if event.is_action_pressed("restart"):
		respawn_player()
	# Playtest cheat: G toggles god mode (no input-map entry needed).
	elif event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_G:
		set_god_level((god_level + 1) % GOD_SPEEDS.size())
	# God mode: 0-5 jump to the start of that chamber.
	elif god_mode and event is InputEventKey and event.pressed and not event.echo:
		var key: Key = (event as InputEventKey).physical_keycode
		if key >= KEY_0 and key <= KEY_5:
			jump_to_chamber(key - KEY_0)


func set_god_level(level: int) -> void:
	god_level = level
	god_mode = level > 0
	god_speed_mult = GOD_SPEEDS[level]
	_god_label.visible = god_mode
	_god_label.text = "GOD MODE  %sx   ·   0-5 jump to chamber" % str(god_speed_mult)
	print("God mode ", _god_label.text if god_mode else "OFF")


func set_invincibility(enabled: bool) -> void:
	# Public assist preserves normal movement speed.
	god_level = 0
	god_mode = enabled
	god_speed_mult = 1.0
	_god_label.visible = enabled
	_god_label.text = "Invincibility active"


## Load chamber `number` from its start. Does nothing if that chamber isn't built yet.
func jump_to_chamber(number: int) -> void:
	var path: String = CHAMBER_PATH % number
	if not ResourceLoader.exists(path):
		print("No chamber ", number, " yet")
		return
	go_to_chamber(path)


## The line a guard says as he kills you; shown over the black on the next respawn.
func set_death_line(line: String) -> void:
	_death_line = line


func set_checkpoint(pos: Vector2) -> void:
	checkpoint = pos
	has_checkpoint = true


## Next respawn starts from the chamber's own start.
func clear_checkpoint() -> void:
	has_checkpoint = false
	checkpoint = Vector2.ZERO


func reset_death_hints() -> void:
	_hazard_deaths.clear()


func _set_lives(remaining: int) -> void:
	if lives != remaining:
		lives = remaining
		lives_changed.emit(lives)


func spend_life(hazard: Node, hint: String) -> String:
	var next_hint: String = ""
	if hazard != null and not hint.is_empty():
		var scene: Node = get_tree().current_scene
		if scene != null and scene.is_ancestor_of(hazard):
			var key: String = scene.scene_file_path + ":" + str(scene.get_path_to(hazard))
			_hazard_deaths[key] = _hazard_deaths.get(key, 0) + 1
			if _hazard_deaths[key] == DEATH_HINT_THRESHOLD:
				next_hint = hint
	_set_lives(lives - 1)
	death_count += 1
	player_died.emit()
	return next_hint


## Fade to black, reload the chamber (which resets every puzzle), and fade back in.
## The player reads `checkpoint` in its _ready() and places itself there.
func respawn_player(hazard: Node = null, hint: String = "", lost_life: bool = false) -> void:
	if _busy:
		return
	_busy = true
	var next_hint: String = spend_life(hazard, hint) if lost_life else ""
	var out_of_lives: bool = lives == 0
	await _fade(1.0)
	var caption: String = "Out of lives. Restarting chamber." if out_of_lives else _death_line
	if not caption.is_empty():
		_death_caption.say(caption, -1.0)
		await get_tree().create_timer(DEATH_LINE_HOLD).timeout
		_death_caption.hide_text()
	_death_line = ""
	if out_of_lives:
		clear_checkpoint()
		_set_lives(MAX_LIVES)
	get_tree().reload_current_scene()
	# Wait for the new scene to finish entering the tree before revealing it.
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(0.0)
	_busy = false
	if not next_hint.is_empty():
		respawn_hint.emit(next_hint)


## Move to another chamber. Checkpoints belong to a chamber, so they are cleared.
func go_to_chamber(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_death_line = ""
	await _fade(1.0)
	clear_checkpoint()
	_set_lives(MAX_LIVES)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	chamber_changed.emit(scene_path)
	await _fade(0.0)
	_busy = false


func is_transitioning() -> bool:
	return _busy


func _fade(target_alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target_alpha, FADE_TIME)
	await tween.finished
