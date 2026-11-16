extends CharacterBody3D
## A guard: patrols, sees, hears, fills a detection meter and reacts (stealth_spec.md §3, §6).
## A capsule stand-in: the Visual node is what the modeller replaces.
##
## The segment root is his director: it owns the alarm, the crisis level and what the overlay
## shows. Guards never read input.

const L := preload("res://stealth/layers.gd")
const Draw := preload("res://stealth/draw.gd")

enum State { PATROL, SUSPICIOUS, ALARMED, SEARCHING, KNOCKED_OUT }
## What the director lets the overlay draw right now.
enum Overlay { NONE, FACING, FULL }

const CONE_COLORS := {
	State.PATROL: Color(1.0, 1.0, 0.85, 0.16),
	State.SUSPICIOUS: Color(1.0, 0.85, 0.2, 0.26),
	State.ALARMED: Color(1.0, 0.2, 0.15, 0.3),
	State.SEARCHING: Color(1.0, 0.55, 0.15, 0.24),
	State.KNOCKED_OUT: Color(1, 1, 1, 0),
}
const METER_COLOR := Color(1.0, 0.3, 0.1, 0.55)
const HEARING_COLOR := Color(0.6, 0.85, 1.0, 0.22)
const MARKS := {
	State.PATROL: "", State.SUSPICIOUS: "?", State.ALARMED: "!",
	State.SEARCHING: "...", State.KNOCKED_OUT: "z",
}
const MARK_COLORS := {
	State.PATROL: Color.WHITE, State.SUSPICIOUS: Color(1.0, 0.85, 0.2),
	State.ALARMED: Color(1.0, 0.25, 0.2), State.SEARCHING: Color(1.0, 0.6, 0.2),
	State.KNOCKED_OUT: Color(0.7, 0.7, 0.7),
}

@export_group("Patrol")
## A node whose Marker3D children are the patrol points, in order. One marker makes a
## sentry who stands there facing the marker's -Z. None: he stands where he was placed.
@export var patrol: NodePath
## true: after the last point go to the first. false: walk the points back and forth.
@export var patrol_loop := true
@export var patrol_wait := 1.5
@export_group("Vision")
@export var cone_angle_deg := 70.0
@export var cone_length := 9.0
@export var eye_height := 1.5
## A height difference above this counts as high ground.
@export var height_step := 1.0
@export_group("Hearing")
@export var hearing_radius := 5.0
@export_group("Detection meter")
@export var fill_near := 2.5        ## per second, seen at arm's length
@export var fill_far := 0.5         ## per second, seen at the cone's far edge
@export var fill_heard := 0.3       ## per second, footsteps only
@export var drain := 0.35           ## per second
@export var drain_delay := 0.5      ## seconds unnoticed before it drains
@export var suspicious_at := 0.4    ## he goes to look once the meter passes this
@export var search_meter := 0.5     ## where the meter sits when an alarm drops to searching
@export_group("Speeds")
@export var patrol_speed := 1.8
@export var suspicious_speed := 2.4
@export var alarm_speed := 4.0
@export var search_speed := 2.4
@export var turn_speed := 6.0       ## radians per second
@export var look_turn_speed := 1.2  ## while looking around on the spot
@export var gravity := 20.0
@export_group("Timings")
@export var suspicious_look_time := 3.0
@export var search_time := 8.0
@export var search_radius := 4.0
@export var search_pause := 1.0
@export var catch_distance := 1.1
@export_group("Drawing")
@export var cone_rays := 24
@export var floor_probe_steps := 6
@export var facing_marker_length := 1.4

var state := State.PATROL
var meter := 0.0
var director: Node
var player: CharacterBody3D

var _points: Array[Vector3] = []
var _sentry_yaw := 0.0
var _patrol_i := 0
var _patrol_dir := 1
var _wait := 0.0
var _path := PackedVector3Array()
var _path_i := 0
var _dest := Vector3.ZERO
var _has_dest := false
var _stuck := 0.0
var _interest := Vector3.ZERO
var _timer := 0.0
var _unnoticed := 0.0
var _search_center := Vector3.ZERO
var _search_point := Vector3.ZERO
var _home: Transform3D

var _cone: MeshInstance3D
var _cone_mesh := ImmediateMesh.new()
var _cone_mat: StandardMaterial3D
var _meter_mat: StandardMaterial3D
var _hearing: MeshInstance3D

@onready var _mark: Label3D = $Mark


func _ready() -> void:
	add_to_group(&"stealth_guard")
	_home = global_transform
	_sentry_yaw = global_rotation.y
	var path_node := get_node_or_null(patrol)
	if path_node:
		for child in path_node.get_children():
			if child is Node3D:
				_points.append(child.global_position)
				_sentry_yaw = child.global_rotation.y
	if _points.is_empty():
		_points.append(global_position)
	_cone_mat = Draw.flat_material(CONE_COLORS[State.PATROL])
	_meter_mat = Draw.flat_material(METER_COLOR)
	_cone = Draw.mesh_instance(_cone_mesh, null)
	add_child(_cone)
	var hearing_mesh := Draw.ring_mesh(hearing_radius, 0.06)
	_hearing = Draw.mesh_instance(hearing_mesh, Draw.flat_material(HEARING_COLOR))
	_hearing.position.y = 0.04
	add_child(_hearing)
	_set_state(State.PATROL)


func setup(director_: Node, player_: CharacterBody3D) -> void:
	director = director_
	player = player_


# --- what he perceives ---

func is_knocked_out() -> bool:
	return state == State.KNOCKED_OUT


## Suspicious, alarmed or searching.
func is_alerted() -> bool:
	return state in [State.SUSPICIOUS, State.ALARMED, State.SEARCHING]


func can_see(target: CharacterBody3D) -> bool:
	if state == State.KNOCKED_OUT:
		return false
	var to := target.global_position - global_position
	to.y = 0.0
	if to.length() > cone_length:
		return false
	if to.length() > 0.05 and _forward().angle_to(to) > deg_to_rad(cone_angle_deg) * 0.5:
		return false
	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3.UP * eye_height
	if not _ray_clear(space, eye, target.sight_point(), L.SIGHT):
		return false
	# Low cover hides him only while he crouches: tested low and flat, so it holds whatever
	# the distances are.
	if target.crouched:
		var low := target.global_position + Vector3.UP * 0.5
		if not _ray_clear(space, Vector3(global_position.x, low.y, global_position.z), low, L.COVER):
			return false
	return true


func can_hear(target: CharacterBody3D) -> bool:
	if state == State.KNOCKED_OUT:
		return false
	var reach := minf(hearing_radius, target.footstep_radius())
	return reach > 0.0 and global_position.distance_to(target.global_position) <= reach


# --- what the director tells him ---

func enter_alarm() -> void:
	if state == State.KNOCKED_OUT:
		return
	meter = 1.0
	_set_state(State.ALARMED)


## The alarm lost him: look around where he was last seen, then go back to the patrol.
func start_search(center: Vector3) -> void:
	if state != State.ALARMED:
		return
	meter = search_meter
	_search_center = center
	_search_point = center
	_timer = search_time
	_wait = 0.0
	_set_state(State.SEARCHING)


## Back to the first patrol point as if nothing happened (after a catch).
func reset_to_patrol() -> void:
	if state == State.KNOCKED_OUT:
		return
	global_transform = _home
	velocity = Vector3.ZERO
	meter = 0.0
	_patrol_i = 0
	_patrol_dir = 1
	_enter_patrol()
	redraw()


# --- the loop ---

func _physics_process(delta: float) -> void:
	if director == null or player == null or state == State.KNOCKED_OUT:
		return
	_sense(delta)
	match state:
		State.PATROL: _do_patrol(delta)
		State.SUSPICIOUS: _do_suspicious(delta)
		State.ALARMED: _do_alarmed(delta)
		State.SEARCHING: _do_searching(delta)
	redraw()


func _sense(delta: float) -> void:
	var sees := can_see(player)
	if state == State.ALARMED:
		meter = 1.0
		if sees:
			director.report_sighting(player.global_position)
		return
	var hears := can_hear(player)
	var speed_up: float = director.detection_multiplier()
	if sees:
		var flat := player.global_position - global_position
		flat.y = 0.0
		var closeness := 1.0 - clampf(flat.length() / cone_length, 0.0, 1.0)
		meter += lerpf(fill_far, fill_near, closeness) * speed_up * delta
		_unnoticed = 0.0
	elif hears:
		meter += fill_heard * speed_up * delta
		_unnoticed = 0.0
	else:
		_unnoticed += delta
		if _unnoticed >= drain_delay:
			meter -= drain * delta
	meter = clampf(meter, 0.0, 1.0)
	if meter >= 1.0:
		director.raise_alarm(player.global_position, self)
	elif (sees or hears) and meter >= suspicious_at:
		_enter_suspicious(player.global_position)


func _do_patrol(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		_halt(delta)
		return
	_go_to(_points[_patrol_i])
	if not _advance(delta, patrol_speed):
		return
	if _points.size() == 1:
		_turn_to(_sentry_yaw, delta)
		return
	_wait = patrol_wait
	if patrol_loop:
		_patrol_i = (_patrol_i + 1) % _points.size()
	else:
		if _patrol_i + _patrol_dir < 0 or _patrol_i + _patrol_dir >= _points.size():
			_patrol_dir = -_patrol_dir
		_patrol_i += _patrol_dir


func _do_suspicious(delta: float) -> void:
	_go_to(_interest)
	if _advance(delta, suspicious_speed):
		_timer += delta
		rotation.y += sin(_timer * 2.0) * look_turn_speed * delta
		if _timer >= suspicious_look_time:
			_enter_patrol()


func _do_alarmed(delta: float) -> void:
	_go_to(director.last_seen_pos)
	if _advance(delta, alarm_speed):
		rotation.y += look_turn_speed * delta
	var to := player.global_position - global_position
	if absf(to.y) < height_step and Vector2(to.x, to.z).length() <= catch_distance:
		director.catch_player(self)


func _do_searching(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_enter_patrol()
		return
	if _wait > 0.0:
		_wait -= delta
		_halt(delta)
		rotation.y += look_turn_speed * delta
		return
	_go_to(_search_point)
	if _advance(delta, search_speed):
		_wait = search_pause
		_search_point = _search_center + Vector3(
			randf_range(-search_radius, search_radius), 0.0,
			randf_range(-search_radius, search_radius))


func _enter_patrol() -> void:
	_wait = 0.0
	_has_dest = false
	_set_state(State.PATROL)


func _enter_suspicious(interest: Vector3) -> void:
	_interest = interest
	_timer = 0.0
	_set_state(State.SUSPICIOUS)


func _set_state(value: State) -> void:
	if value != state:
		_has_dest = false
	state = value
	_mark.text = MARKS[value]
	_mark.modulate = MARK_COLORS[value]
	_cone_mat.albedo_color = CONE_COLORS[value]


# --- moving ---

func _go_to(pos: Vector3) -> void:
	if _has_dest and _dest.distance_to(pos) < 0.75:
		return
	_dest = pos
	_has_dest = true
	_path = NavigationServer3D.map_get_path(
		get_world_3d().navigation_map, global_position, pos, true)
	if _path.is_empty():
		_path = PackedVector3Array([pos])
	_path_i = 0
	_stuck = 0.0


## Walks the path. True once he is at its end (and standing).
func _advance(delta: float, speed: float) -> bool:
	while _path_i < _path.size() and _flat_to(_path[_path_i]).length() < 0.35:
		_path_i += 1
	if _path_i >= _path.size():
		_halt(delta)
		return true
	var dir := _flat_to(_path[_path_i]).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_fall(delta)
	move_and_slide()
	_turn_to(atan2(-dir.x, -dir.z), delta)
	var moved := get_real_velocity()
	_stuck = _stuck + delta if Vector2(moved.x, moved.z).length() < speed * 0.2 else 0.0
	if _stuck > 1.5:
		_path_i = _path.size()
	return false


func _halt(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_fall(delta)
	move_and_slide()


func _fall(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta


func _turn_to(yaw: float, delta: float) -> void:
	var diff := wrapf(yaw - rotation.y, -PI, PI)
	rotation.y += clampf(diff, -turn_speed * delta, turn_speed * delta)


func _flat_to(pos: Vector3) -> Vector3:
	var to := pos - global_position
	to.y = 0.0
	return to


func _forward() -> Vector3:
	return -global_basis.z


func _ray_clear(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> bool:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, mask)).is_empty()


# --- the overlay ---

## Draws what the director allows: nothing, a short facing marker with the meter filling
## it, or the whole cone clipped by walls with the hearing ring.
func redraw() -> void:
	var level: int = director.overlay_level() if director else Overlay.NONE
	if state == State.KNOCKED_OUT:
		level = Overlay.NONE
	_hearing.visible = level == Overlay.FULL and state != State.ALARMED
	_cone_mesh.clear_surfaces()
	if level == Overlay.NONE:
		return
	var reach := _cone_reach() if level == Overlay.FULL else _marker_reach()
	_add_fan(reach, 1.0, 0.06, _cone_mat)
	if meter > 0.01:
		_add_fan(reach, meter, 0.08, _meter_mat)


func _add_fan(reach: PackedFloat32Array, scale_: float, height: float, mat: Material) -> void:
	var half := deg_to_rad(cone_angle_deg) * 0.5
	var last := reach.size() - 1
	_cone_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	for i in last:
		var a0 := lerpf(-half, half, float(i) / last)
		var a1 := lerpf(-half, half, float(i + 1) / last)
		_cone_mesh.surface_add_vertex(Vector3(0.0, height, 0.0))
		_cone_mesh.surface_add_vertex(
			Vector3(sin(a0), 0.0, -cos(a0)) * reach[i] * scale_ + Vector3.UP * height)
		_cone_mesh.surface_add_vertex(
			Vector3(sin(a1), 0.0, -cos(a1)) * reach[i + 1] * scale_ + Vector3.UP * height)
	_cone_mesh.surface_end()


func _marker_reach() -> PackedFloat32Array:
	var reach := PackedFloat32Array()
	reach.resize(7)
	reach.fill(facing_marker_length)
	return reach


## How far each ray of the cone gets before a wall (or, while the player crouches, low
## cover) stops it.
func _cone_reach() -> PackedFloat32Array:
	var space := get_world_3d().direct_space_state
	var half := deg_to_rad(cone_angle_deg) * 0.5
	var eye := global_position + Vector3.UP * eye_height
	var low := global_position + Vector3.UP * 0.5
	var crouched: bool = player != null and player.crouched
	var reach := PackedFloat32Array()
	for i in cone_rays + 1:
		var a := lerpf(-half, half, float(i) / cone_rays)
		var dir := global_basis * Vector3(sin(a), 0.0, -cos(a))
		var length := _ray_length(space, eye, dir, cone_length, L.SIGHT)
		if crouched:
			length = minf(length, _ray_length(space, low, dir, cone_length, L.COVER))
		reach.append(_clip_to_floor(space, eye, dir, length))
	return reach


func _ray_length(space: PhysicsDirectSpaceState3D, from: Vector3, dir: Vector3,
		length: float, mask: int) -> float:
	var hit := space.intersect_ray(
		PhysicsRayQueryParameters3D.create(from, from + dir * length, mask))
	return from.distance_to(hit.position) if hit else length


## Step 3 cuts the cone at a drop to lower ground.
func _clip_to_floor(_space: PhysicsDirectSpaceState3D, _eye: Vector3, _dir: Vector3,
		length: float) -> float:
	return length
