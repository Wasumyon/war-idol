class_name FollowCamera
extends Camera2D
## Side-scroller camera: follows the target with built-in smoothing and leads
## slightly in the direction he faces (Limbo-style). Set the limit_* properties
## per chamber in the inspector.

@export var target_path: NodePath
@export var vertical_offset: float = -130.0
@export var look_ahead: float = 90.0
@export var look_ahead_speed: float = 1.5

var _target: Node2D
var _lead: float = 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	if _target:
		global_position = _target.global_position + Vector2(0.0, vertical_offset)
		reset_smoothing()


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var facing: float = 1.0
	if _target is Player:
		facing = float((_target as Player).facing)
	_lead = lerpf(_lead, facing * look_ahead, delta * look_ahead_speed)
	global_position = _target.global_position + Vector2(_lead, vertical_offset)
