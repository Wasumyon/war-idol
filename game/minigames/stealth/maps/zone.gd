@tool
extends Node3D
## A box-shaped region of a stealth map: a concealment patch, a checkpoint or the exit.
## The origin is the centre of the box's floor. No physics: the map asks contains().

const Draw := preload("res://minigames/stealth/draw.gd")

enum Kind { CONCEALMENT, CHECKPOINT, EXIT }

const COLORS := {
	Kind.CONCEALMENT: Color(0.75, 0.9, 0.8, 0.3),
	Kind.CHECKPOINT: Color(0.3, 0.6, 1.0, 0.35),
	Kind.EXIT: Color(0.3, 1.0, 0.45, 0.4),
}

@export var size := Vector3(3, 2, 3):
	set(value):
		size = value
		_rebuild()
@export var kind := Kind.CONCEALMENT:
	set(value):
		kind = value
		_rebuild()

var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group(&"stealth_zone")
	_rebuild()


func contains(world_pos: Vector3) -> bool:
	var p := to_local(world_pos)
	return absf(p.x) <= size.x * 0.5 and absf(p.z) <= size.z * 0.5 \
		and p.y >= -0.3 and p.y <= size.y


## A checkpoint lights up once it is the one in use.
func set_active(on: bool) -> void:
	var color: Color = COLORS[kind]
	if on:
		color.a = 0.7
	(_mesh.material_override as StandardMaterial3D).albedo_color = color


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh == null:
		_mesh = Draw.mesh_instance(BoxMesh.new(), Draw.flat_material(Color.WHITE))
		add_child(_mesh)
	# A patch is drawn as its whole volume, a checkpoint or exit as a pad on the floor.
	var height := size.y if kind == Kind.CONCEALMENT else 0.06
	(_mesh.mesh as BoxMesh).size = Vector3(size.x, height, size.z)
	_mesh.position = Vector3(0, height * 0.5 + 0.02, 0)
	(_mesh.material_override as StandardMaterial3D).albedo_color = COLORS[kind]
