@tool
extends StaticBody3D
## A grey-box piece of a stealth map: one box with a size and a kind. The mesh and the
## collision shape are built from those, so a map scene is one node per block.

const L := preload("res://stealth/layers.gd")

enum Kind { WALL, LOW_COVER, FLOOR }

const COLORS := {
	Kind.WALL: Color(0.42, 0.44, 0.47),
	Kind.LOW_COVER: Color(0.62, 0.52, 0.36),
	Kind.FLOOR: Color(0.23, 0.25, 0.27),
}
const LAYERS := {
	Kind.WALL: L.WALL,
	Kind.LOW_COVER: L.COVER,
	Kind.FLOOR: L.FLOOR,
}

@export var size := Vector3(1, 1, 1):
	set(value):
		size = value
		_rebuild()
@export var kind := Kind.WALL:
	set(value):
		kind = value
		_rebuild()
## The camera rig fades this block while it stands between the camera and the player.
@export var fade_when_blocking := true
@export_range(0.0, 1.0) var faded_transparency := 0.8
@export var fade_time := 0.2

var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _fade: Tween
var _faded := false


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.mesh = BoxMesh.new()
		_mesh.material_override = StandardMaterial3D.new()
		add_child(_mesh)
		_shape = CollisionShape3D.new()
		_shape.shape = BoxShape3D.new()
		add_child(_shape)
	(_mesh.mesh as BoxMesh).size = size
	(_mesh.material_override as StandardMaterial3D).albedo_color = COLORS[kind]
	(_shape.shape as BoxShape3D).size = size
	collision_layer = LAYERS[kind]
	collision_mask = 0


func set_faded(on: bool) -> void:
	if not fade_when_blocking or on == _faded or _mesh == null:
		return
	_faded = on
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_mesh, "transparency", faded_transparency if on else 0.0, fade_time)
