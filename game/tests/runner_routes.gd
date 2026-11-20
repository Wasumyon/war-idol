extends Node
## Data, wiring and replay checks. Run with --fixed-fps 60.

const CALENDAR := preload("res://calendar/calendar_data.gd")
const SEGMENT := preload("res://minigames/runner/runner_segment.tscn")
const RUN := preload("res://minigames/runner/run.tscn")

var _failures := 0


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		_failures += 1


func _ready() -> void:
	_check_data()
	_check_wiring()
	# Let startup and deferred frees finish before measuring fixed-frame replays.
	await get_tree().process_frame
	await get_tree().process_frame
	var first := await _replay(1234)
	var second := await _replay(1234)
	var different := await _replay(99)
	_check(not first.is_empty(), "600 frames produce a non-empty spawn log")
	_check(first == second, "seed 1234 replays the same 600-frame spawn log")
	_check(first != different, "seed 99 produces a different spawn log")
	var kinds := {}
	var valid_log := true
	for entry in first:
		kinds[entry.kind] = true
		valid_log = valid_log and entry.size() == 3 and entry.z is int
		if entry.kind in ["target", "emitter"]:
			valid_log = valid_log and entry.lane >= 0 and entry.lane < GameState.lane_count
		else:
			valid_log = valid_log and entry.lane == -1
	_check(valid_log, "spawn entries contain kind, lane and integer z")
	_check(kinds.has("battle") and kinds.has("laser")
		and (kinds.has("drone_hover") or kinds.has("drone_cross"))
		and (kinds.has("target") or kinds.has("emitter")), "replay covers ground, air, battles and lasers")
	print("runner routes: %d failures" % _failures)
	get_tree().quit(1 if _failures else 0)


func _check_data() -> void:
	var zones := {}
	for entry: Dictionary in CALENDAR.SEGMENTS.values():
		var args: Dictionary = entry.get("args", {})
		if args.has("zone"):
			zones[str(args.zone)] = true
	_check(not zones.is_empty(), "calendar supplies runner zones")
	for zone: String in zones:
		var path := "res://minigames/runner/routes/%s.tres" % zone
		_check(ResourceLoader.exists(path), "%s has a zone file" % zone)
		var def := load(path) as RouteDef
		_check(def != null, "%s loads as RouteDef" % zone)
		if def == null:
			continue
		_check(def.zone_id == zone and not def.display_name.is_empty(), "%s has its identity" % zone)
		_check(def.sky_texture != null and def.far_texture != null, "%s has both textures" % zone)
		_check(def.duration > 0.0 and def.row_spacing > 0.0 and def.air_interval > 0.0
			and def.battle_interval > 0.0 and def.laser_interval > 0.0, "%s has positive intervals" % zone)
		_check(def.cluster_min <= def.cluster_max, "%s has ordered cluster counts" % zone)
		var valid_shots := not def.drone_shots.is_empty()
		for shot in def.drone_shots:
			valid_shots = valid_shots and shot in Drone.Shot.values() and float(def.drone_shots[shot]) > 0.0
		_check(valid_shots, "%s has valid shot types with positive weights" % zone)


func _check_wiring() -> void:
	# Check every calendar runner entry through the unchanged begin contract.
	for entry: Dictionary in CALENDAR.SEGMENTS.values():
		if entry.get("source") != "res://minigames/runner/runner_segment.tscn":
			continue
		var seg: Node = SEGMENT.instantiate()
		seg.begin(entry.args)
		add_child(seg)
		_check(seg._run.route_def.zone_id == entry.args.zone, "calendar begin selects %s" % entry.args.zone)
		_check(seg._args.route == entry.args.route, "route difficulty is stored")
		seg.free()
	for zone in ["unknown_zone", ""]:
		var seg: Node = SEGMENT.instantiate()
		seg.begin({"zone": zone})
		add_child(seg)
		_check(seg._run.route_def.zone_id == "supply_road", "unknown/missing zone falls back to supply_road")
		seg.free()

	var def := RouteDef.load_zone("supply_road").duplicate() as RouteDef
	def.duration = 5.0
	def.start_shields = 7
	def.flat_dark = Color(0.2, 0.3, 0.4)
	def.flat_light = Color(0.5, 0.6, 0.7)
	def.track_color = Color(0.1, 0.2, 0.3)
	def.sky_texture = GradientTexture2D.new()
	def.far_texture = GradientTexture2D.new()
	var run: Node = RUN.instantiate()
	run.route_def = def
	run.rng = RandomNumberGenerator.new()
	run.rng.seed = 1234
	add_child(run)
	_check(is_equal_approx(run.run_timer.wait_time, 5.0)
		and is_equal_approx(run.run_timer.time_left, 5.0), "duration 5 reaches the live timer")
	_check(run.shields == 7, "starting shields come from the def")
	var spawner: Node = run.get_node("Spawner")
	_check(spawner.route_def == def and spawner.rng == run.rng, "spawner reads the run's def and generator")
	_check(run.get_node("Backdrop/Sky").material_override.albedo_texture == def.sky_texture
		and run.get_node("Backdrop/Far").material_override.albedo_texture == def.far_texture,
		"backdrop uses the def's textures")
	var material: ShaderMaterial = run.get_node("Ground").material_override
	_check(material.get_shader_parameter("flat_dark") == def.flat_dark
		and material.get_shader_parameter("flat_light") == def.flat_light
		and material.get_shader_parameter("track_color") == def.track_color, "ground uses the def's palette")
	# Standalone scene initializes its own def and RNG without modifying shared materials.
	var standalone: Node = RUN.instantiate()
	add_child(standalone)
	_check(standalone.route_def.zone_id == "supply_road" and standalone.rng != null,
		"standalone run initializes the default zone and generator")
	for path in ["Backdrop/Sky", "Backdrop/Far", "Ground"]:
		_check(run.get_node(path).material_override != standalone.get_node(path).material_override,
			"%s material belongs to its run" % path)
	_check(standalone.get_node("Backdrop/Sky").material_override.albedo_texture
		== standalone.route_def.sky_texture, "custom textures leave the default backdrop unchanged")
	standalone.free()
	run.free()

	var seeded: Node = SEGMENT.instantiate()
	seeded.begin({"zone": "supply_road", "seed": 1234})
	add_child(seeded)
	var state: int = seeded._run.rng.state
	seeded._run.rng.randf()
	seeded.restart()
	_check(seeded._run.rng.seed == 1234 and seeded._run.rng.state == state,
		"restart resets an explicit seed")
	seeded.free()
	var random: Node = SEGMENT.instantiate()
	random.begin({"zone": "supply_road"})
	add_child(random)
	var old_seed: int = random._run.rng.seed
	random.restart()
	_check(random._run.rng.seed != old_seed, "restart without a seed randomizes again")
	random.free()


func _replay(seed_value: int) -> Array[Dictionary]:
	# Each run starts at the same point in the frame. Only one segment is live,
	# since the existing runner finds players and battle groups through the tree.
	await get_tree().process_frame
	var seg: Node = SEGMENT.instantiate()
	seg.begin({"zone": "supply_road", "seed": seed_value})
	add_child(seg)
	for frame in 600:
		await get_tree().process_frame
	var log: Array[Dictionary] = seg._run.get_node("Spawner").spawn_log.duplicate(true)
	seg.free()
	return log
