extends Sprite2D
## Orthographic sprites baked from guard1.glb, shared by both guard types.
const SHEET: Texture2D = preload("res://minigames/tunnel/art/sprites/guard/guard_model_animations.png")
const COUNTS: Array[int] = [32, 16, 16]
const DURATIONS: Array[float] = [5.8666668, 1.0666667, 0.7333333]
const START_ROWS: Array[int] = [0, 2, 3]
var _row: int = -1
var _clock: float = 0.0

func _init() -> void:
	texture = SHEET
	centered = false
	region_enabled = true
	region_filter_clip_enabled = true
	# Preserve the previous 125px gameplay height and floor anchor.
	scale = Vector2.ONE * (125.0 / 190.0)
	offset = Vector2(-128, -243)
	animate(0.0, false, false)

func animate(delta: float, moving: bool, running: bool, speed_scale: float = 1.0) -> void:
	var row: int = 2 if running and moving else (1 if moving else 0)
	if row != _row:
		_row = row
		_clock = 0.0
	var playback_speed: float = speed_scale if row == 1 else 1.0
	_clock = fmod(_clock + delta * playback_speed, DURATIONS[row])
	var frame_index: int = mini(int(_clock / DURATIONS[row] * COUNTS[row]), COUNTS[row] - 1)
	region_rect = Rect2((frame_index % 16) * 256, (START_ROWS[row] + frame_index / 16) * 256, 256, 256)
