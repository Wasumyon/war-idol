extends Node3D
class_name LaneSpawner
## Spawns the world ahead of the runner.
##
## HIERARCHY / FOCUS: side battles come in CLUSTERS (a battle line, not a lone
## pocket), and only one cluster runs at a time - while it does, air spawns are
## slowed so the player reads one feature, not three.
##
##  GROUND (every row_spacing): FilmTarget or HazardEmitter, IN a lane.
##  AIR    (every air_interval): a Drone OFF the grid - CROSS or HOVER.
##  BATTLE (every battle_interval): a cluster of side battles, far outside the
##         lane corridor.

# The parent's _ready runs after this child's. Read its configuration when
# processing starts, so run.tscn also works on its own with the run's defaults.
var _run: Node
var route_def: RouteDef:
	get:
		return _run.route_def
var rng: RandomNumberGenerator:
	get:
		return _run.rng

var spawn_log: Array[Dictionary] = []

# Relative density per lane, DERIVED from GameState.lane_count in _ready():
# outermost lanes densest, centre sparsest (mirrored). Never hand-edited.
var lane_weights: Array[float] = []

var _player: Node3D
var _next_z := 0.0
var _started := false
var _cleanup := 0.0
var _air_cool := 0.0
var _battle_cool := 0.0
var _laser_cool := 0.0
var _last_emitter_z := 100000.0
var _last_lane := -1


func _ready() -> void:
	_run = get_parent()
	_player = get_tree().get_first_node_in_group("player")
	_build_lane_weights()


## Outermost lane = 3.0, centre = 1.0, mirrored. Matches [3,2,1,2,3] for 5 lanes.
func _build_lane_weights() -> void:
	lane_weights.clear()
	var n: int = GameState.lane_count
	if n <= 1:
		lane_weights.append(1.0)
		return
	var mid := (n - 1) / 2.0
	for i in n:
		var d: float = abs(float(i) - mid) / mid
		lane_weights.append(1.0 + 2.0 * d)


func lane_x(index: int) -> float:
	return GameState.lane_x(index)


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	if not _started:
		_next_z = _player.global_position.z - route_def.spawn_ahead
		_started = true

	# --- ground rows ---
	var horizon := _player.global_position.z - route_def.spawn_ahead
	while _next_z > horizon:
		_spawn_row(_next_z)
		_next_z -= route_def.row_spacing

	var feature_busy := get_tree().get_nodes_in_group("pocket").size() > 0

	# --- air layer (slowed while a battle cluster is running) ---
	_air_cool -= delta
	if _air_cool <= 0.0:
		_air_cool = route_def.air_interval * rng.randf_range(0.7, 1.3)
		if feature_busy:
			_air_cool *= 2.0
		else:
			_spawn_air()

	# --- battle clusters (only when nothing else is featuring) ---
	_battle_cool -= delta
	if _battle_cool <= 0.0:
		_battle_cool = route_def.battle_interval * rng.randf_range(0.8, 1.2)
		if not feature_busy:
			_spawn_battle()

	# --- filmer-targeting lasers (duck to survive) ---
	_laser_cool -= delta
	if route_def.laser_interval > 0.0 and _laser_cool <= 0.0:
		_laser_cool = route_def.laser_interval * rng.randf_range(0.8, 1.2)
		_spawn_laser()

	# --- recycle what the player has passed ---
	_cleanup -= delta
	if _cleanup <= 0.0:
		_cleanup = 1.0
		for child in get_children():
			if child is Node3D and child.global_position.z > _player.global_position.z + 40.0:
				child.queue_free()


func _spawn_row(z: float) -> void:
	if rng.randf() > route_def.spawn_chance:
		return

	var lane := _pick_lane()
	if lane == _last_lane:
		lane = (lane + 1) % GameState.lane_count
	_last_lane = lane

	if rng.randf() < route_def.emitter_chance and abs(z - _last_emitter_z) >= route_def.emitter_min_gap:
		_last_emitter_z = z
		var e := HazardEmitter.new()
		e.rng = rng
		add_child(e)
		e.global_position = Vector3(lane_x(lane), 3.5, z)
		_log_spawn("emitter", lane, z)
		return

	var t := FilmTarget.new()
	t.flat = rng.randf() < route_def.flat_chance
	t.value = 0.8 if t.flat else 1.6
	add_child(t)
	var y := 0.25 if t.flat else 1.4
	t.global_position = Vector3(lane_x(lane), y, z)
	_log_spawn("target", lane, z)


func _spawn_air() -> void:
	var z := _player.global_position.z - route_def.air_spawn_ahead
	# Each drone is typed: it only ever fires this one munition.
	var shot := _pick_drone_shot()
	var hovering := rng.randf() < route_def.hover_chance
	if hovering and get_tree().get_nodes_in_group("hover_drone").size() >= route_def.max_hover:
		hovering = false

	if hovering:
		var dh := Drone.new()
		dh.rng = rng
		dh.mode = Drone.Mode.HOVER
		dh.shot = shot
		dh.tier = 2
		dh.value = 2.0
		add_child(dh)
		dh.global_position = Vector3(rng.randf_range(-14.0, 14.0), rng.randf_range(7.0, 11.0), z)
		_log_spawn("drone_hover", -1, z)
	else:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var dc := Drone.new()
		dc.rng = rng
		dc.mode = Drone.Mode.CROSS
		dc.shot = shot
		dc.tier = 3
		dc.value = 2.8
		dc.lateral_speed = rng.randf_range(18.0, 28.0) * -side
		add_child(dc)
		dc.global_position = Vector3(side * 26.0, rng.randf_range(6.0, 11.0), z)
		_log_spawn("drone_cross", -1, z)


func _pick_drone_shot() -> int:
	var total := 0.0
	for weight in route_def.drone_shots.values():
		total += float(weight)
	var pick := rng.randf() * total
	for shot in route_def.drone_shots:
		pick -= float(route_def.drone_shots[shot])
		if pick <= 0.0:
			return int(shot)
	return Drone.Shot.BEAM


## A road-wide beam at streamer height; duck to drop below it.
func _spawn_laser() -> void:
	var z := _player.global_position.z - rng.randf_range(95.0, 130.0)
	var l := Laser.new()
	add_child(l)
	l.global_position = Vector3(0.0, 1.62, z)
	_log_spawn("laser", -1, z)


## A cluster of battles on one side, grouped so it reads as one engagement.
func _spawn_battle() -> void:
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var count := rng.randi_range(route_def.cluster_min, route_def.cluster_max)
	var base_z := _player.global_position.z - rng.randf_range(route_def.cluster_z_min, route_def.cluster_z_max)
	for i in count:
		var p := BattlePocket.new()
		p.rng = rng
		add_child(p)
		var x := side * (route_def.pocket_x + rng.randf_range(-route_def.cluster_x_spread, route_def.cluster_x_spread))
		var z := base_z + rng.randf_range(-route_def.cluster_z_spread, route_def.cluster_z_spread)
		p.global_position = Vector3(x, 0.0, z)
		_log_spawn("battle", -1, z)


func _log_spawn(kind: String, lane: int, z: float) -> void:
	spawn_log.append({"kind": kind, "lane": lane, "z": roundi(z)})


## Weighted random lane pick - the "hazard density" lever.
func _pick_lane() -> int:
	var total := 0.0
	for w in lane_weights:
		total += w
	var r := rng.randf() * total
	for i in lane_weights.size():
		r -= lane_weights[i]
		if r <= 0.0:
			return i
	return GameState.lane_count / 2
