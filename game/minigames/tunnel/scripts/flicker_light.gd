class_name FlickerLight
extends PointLight2D
## A fire light (Chamber 5's furnace): smooth noise on energy and size.
## Scale `energy` freely (EndingSequence swells it); the flicker rides on top.

@export var strength: float = 0.18
@export var speed: float = 3.0

var _noise: FastNoiseLite = FastNoiseLite.new()
var _t: float = 0.0
var _base_scale: float = 1.0
var _last: float = 1.0


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.8
	_base_scale = texture_scale


func _process(delta: float) -> void:
	_t += delta
	var f: float = 1.0 + _noise.get_noise_1d(_t * speed * 10.0) * strength
	# Undo last frame's flicker so outside tweens of energy still work.
	energy = energy / _last * f
	_last = f
	texture_scale = _base_scale * (1.0 + (f - 1.0) * 0.3)
