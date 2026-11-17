extends Node2D
## Audible movement only: this never calls guard hearing or worm detection.
var heavy: bool = false
var surface_override: String = ""
var _actor: Node2D
var _previous: Vector2
var _distance: float = 0.0
var _sound: AudioStreamPlayer2D
var _clips: Dictionary = {}
var _last_variant: int = -1


func _ready() -> void:
	_actor = get_parent() as Node2D
	_previous = _actor.global_position
	# Run after the actor has moved, including the guards' scripted movement.
	process_physics_priority = 10
	_sound = AudioStreamPlayer2D.new()
	_sound.max_distance = 1050.0 if heavy else 800.0
	_sound.attenuation = 1.5
	_sound.max_polyphony = 2
	add_child(_sound)
	for surface: String in ["concrete", "metal"]:
		var clips: Array[AudioStream] = []
		for i: int in range(3):
			clips.append(load("res://minigames/tunnel/art/sfx/step_%s_%s_%d.wav" % ["guard" if heavy else "player", surface, i]) as AudioStream)
		_clips[surface] = clips


func _physics_process(delta: float) -> void:
	var here: Vector2 = _actor.global_position
	var moved: float = absf(here.x - _previous.x)
	_previous = here
	var enabled: bool = moved > 0.1 and moved < 50.0
	if not heavy and _actor is CharacterBody2D:
		enabled = enabled and (_actor as CharacterBody2D).is_on_floor()
	if not heavy:
		enabled = enabled and not _actor.get("is_dead") and not _actor.get("is_hidden")
	if not enabled:
		_distance = 0.0
		return
	var speed: float = moved / maxf(delta, 0.001)
	var stride: float = 55.0 if heavy else 75.0
	var running: bool = speed > (190.0 if heavy else 280.0)
	if running:
		stride *= 1.35
	_distance += moved
	if _distance < stride:
		return
	_distance = fmod(_distance, stride)
	var surface: String = surface_override
	if surface.is_empty():
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(here + Vector2(0, -8), here + Vector2(0, 18), 1)
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		surface = str(hit["collider"].get_meta("footstep_surface", "concrete")) if not hit.is_empty() else "concrete"
	if not _clips.has(surface):
		surface = "concrete"
	var variant: int = (randi_range(1, 2) + _last_variant + 3) % 3
	_last_variant = variant
	_sound.stream = _clips[surface][variant]
	_sound.pitch_scale = randf_range(0.93, 1.06)
	if running and not heavy:
		_sound.pitch_scale *= 0.88
	var running_boost: float = 3.0 if heavy else 6.0
	_sound.volume_db = (-12.0 if heavy else -18.0) + (running_boost if running else 0.0) + randf_range(-1.0, 1.0)
	_sound.play()
