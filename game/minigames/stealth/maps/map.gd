extends Node3D
## Root of a stealth map. A map is data: blocks, zones, a PlayerStart marker, and guards with
## their patrol markers. This script collects them and bakes the guards' navigation mesh
## from the blocks at load.

const L := preload("res://minigames/stealth/layers.gd")
const Zone := preload("res://minigames/stealth/maps/zone.gd")

@export_group("Navigation")
@export var nav_agent_radius := 0.5
@export var nav_agent_height := 1.5
@export var nav_max_climb := 0.25

var guards: Array[Node] = []
var _zones: Array[Node] = []


func _ready() -> void:
	for node in get_tree().get_nodes_in_group(&"stealth_zone"):
		if is_ancestor_of(node):
			_zones.append(node)
	for node in get_tree().get_nodes_in_group(&"stealth_guard"):
		if is_ancestor_of(node):
			guards.append(node)
	_bake_navigation()


func start_position() -> Vector3:
	var start := get_node_or_null(^"PlayerStart") as Node3D
	return start.global_position if start else global_position


func is_concealed(pos: Vector3) -> bool:
	return _zone_at(pos, Zone.Kind.CONCEALMENT) != null


func checkpoint_at(pos: Vector3) -> Node3D:
	return _zone_at(pos, Zone.Kind.CHECKPOINT)


func is_exit(pos: Vector3) -> bool:
	return _zone_at(pos, Zone.Kind.EXIT) != null


func _zone_at(pos: Vector3, kind: int) -> Node3D:
	for zone in _zones:
		if zone.kind == kind and zone.contains(pos):
			return zone
	return null


func _bake_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = L.SOLID
	mesh.agent_radius = nav_agent_radius
	mesh.agent_height = nav_agent_height
	mesh.agent_max_climb = nav_max_climb
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, self)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	var region := NavigationRegion3D.new()
	region.name = "Navigation"
	region.navigation_mesh = mesh
	add_child(region)
