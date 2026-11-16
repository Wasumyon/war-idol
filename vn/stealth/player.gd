extends CharacterBody3D
## The narrator on foot. A capsule stand-in: the Visual node is what the modeller replaces.

@export_group("Movement")
@export var walk_speed := 4.5
@export var crouch_speed := 2.0
@export var acceleration := 30.0
@export var turn_speed := 12.0
@export var gravity := 20.0
@export_group("Footsteps")
## How far his footsteps carry. A guard hears them inside this and inside his own hearing range.
@export var walk_noise_radius := 5.0
@export var crouch_noise_radius := 1.75
@export_group("Body")
@export var stand_height := 1.7
@export var crouch_height := 1.0

var crouched := false
## The camera's yaw, so that W is always up the screen. Set by the segment root.
var move_yaw := 0.0
var frozen := false

@onready var _collision: CollisionShape3D = $Collision
@onready var _visual: Node3D = $Visual


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if not frozen:
		input = Input.get_vector(&"stealth_left", &"stealth_right", &"stealth_up", &"stealth_down")
	_set_crouched(not frozen and Input.is_action_pressed(&"stealth_crouch"))
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, move_yaw)
	var target := dir * (crouch_speed if crouched else walk_speed)
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	if dir.length_squared() > 0.01:
		_visual.rotation.y = lerp_angle(
			_visual.rotation.y, atan2(-dir.x, -dir.z), minf(turn_speed * delta, 1.0))


func is_moving() -> bool:
	return Vector2(velocity.x, velocity.z).length() > 0.5


## 0 while standing still.
func footstep_radius() -> float:
	if not is_moving():
		return 0.0
	return crouch_noise_radius if crouched else walk_noise_radius


## The point a guard's line of sight is tested against.
func sight_point() -> Vector3:
	return global_position + Vector3.UP * (crouch_height if crouched else stand_height) * 0.7


func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	reset_physics_interpolation()


## Shown half-transparent while nothing can see him (a concealment patch).
func set_concealed(on: bool) -> void:
	for child in _visual.get_children():
		if child is GeometryInstance3D:
			child.transparency = 0.6 if on else 0.0


func _set_crouched(on: bool) -> void:
	if on == crouched:
		return
	crouched = on
	var height := crouch_height if on else stand_height
	(_collision.shape as CapsuleShape3D).height = height
	_collision.position.y = height * 0.5
	_visual.scale.y = height / stand_height
