extends Node3D
## Orthographic follow camera with two presets, isometric and top-down, and a fade for
## whatever stands between the camera and the target. Expects a Camera3D child.

const L := preload("res://minigames/stealth/layers.gd")

enum Preset { ISOMETRIC, TOP_DOWN }

@export var preset := Preset.ISOMETRIC
@export_group("Isometric")
@export var iso_yaw_deg := 45.0
@export var iso_pitch_deg := 50.0
@export var iso_size := 16.0     ## metres of world across the screen's height
@export_group("Top-down")
@export var top_yaw_deg := 0.0
@export var top_pitch_deg := 90.0
@export var top_size := 20.0
@export_group("Rig")
@export var distance := 40.0
@export var follow_speed := 8.0
@export var look_height := 0.9   ## the point on the target the camera centres on
@export var switch_time := 0.5
@export_group("Wall fade")
@export var fade_probe_side := 0.6
@export var fade_probe_up := 0.7

var target: Node3D

var _yaw := 0.0
var _pitch := 0.0
var _size := 16.0
var _switch: Tween
var _faded := {}

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	var p := _values(preset)
	_yaw = p.yaw
	_pitch = p.pitch
	_size = p.size
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_apply()


## The yaw the player's movement is measured from, in radians.
func yaw() -> float:
	return _yaw


func toggle() -> void:
	set_preset(Preset.TOP_DOWN if preset == Preset.ISOMETRIC else Preset.ISOMETRIC)


func set_preset(value: Preset) -> void:
	preset = value
	var p := _values(value)
	if _switch:
		_switch.kill()
	_switch = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	_switch.tween_property(self, "_yaw", p.yaw, switch_time)
	_switch.tween_property(self, "_pitch", p.pitch, switch_time)
	_switch.tween_property(self, "_size", p.size, switch_time)


func snap_to_target() -> void:
	if target:
		global_position = target.global_position + Vector3.UP * look_height


func _process(delta: float) -> void:
	if target:
		var aim := target.global_position + Vector3.UP * look_height
		global_position = global_position.lerp(aim, minf(follow_speed * delta, 1.0))
	_apply()


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	var back := global_basis.z
	var side := global_basis.x * fade_probe_side
	var aim := target.global_position + Vector3.UP * look_height
	var blockers := {}
	for offset: Vector3 in [Vector3.ZERO, side, -side,
			Vector3.UP * fade_probe_up, Vector3.DOWN * fade_probe_up]:
		_collect_blockers(aim + offset + back * distance, aim + offset, blockers)
	for body in blockers:
		if not _faded.has(body):
			body.set_faded(true)
	for body in _faded:
		if not blockers.has(body) and is_instance_valid(body):
			body.set_faded(false)
	_faded = blockers


func _collect_blockers(from: Vector3, to: Vector3, into: Dictionary) -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, L.SOLID)
	var exclude: Array[RID] = []
	for i in 8:
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return
		if hit.collider.has_method(&"set_faded"):
			into[hit.collider] = true
		exclude.append(hit.rid)


func _apply() -> void:
	rotation = Vector3(-_pitch, _yaw, 0.0)
	_camera.position = Vector3(0.0, 0.0, distance)
	_camera.size = _size


func _values(which: Preset) -> Dictionary:
	if which == Preset.TOP_DOWN:
		return {yaw = deg_to_rad(top_yaw_deg), pitch = deg_to_rad(top_pitch_deg), size = top_size}
	return {yaw = deg_to_rad(iso_yaw_deg), pitch = deg_to_rad(iso_pitch_deg), size = iso_size}
