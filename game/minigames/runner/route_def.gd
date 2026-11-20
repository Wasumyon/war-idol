class_name RouteDef extends Resource
## Zone tuning. Defaults preserve the original runner; difficulty is not applied yet.

@export_group("Id")
@export var zone_id := "supply_road"
@export var display_name := "Supply road"

@export_group("Run")
@export var duration := 90.0
@export var start_shields := 3
@export var follow_per_sec := 10.0
@export var donation_rate := 0.004

@export_group("Look")
@export var sky_texture: Texture2D
@export var far_texture: Texture2D
@export var flat_dark := Color(0.17, 0.12, 0.05)
@export var flat_light := Color(0.52, 0.42, 0.14)
@export var track_color := Color(0.13, 0.11, 0.09)

@export_group("Ground layer")
@export var spawn_ahead := 150.0
@export var row_spacing := 20.0
@export var spawn_chance := 0.9
@export var emitter_chance := 0.3
@export var emitter_min_gap := 55.0
@export var flat_chance := 0.65

@export_group("Air layer")
@export var air_interval := 2.0
@export var air_spawn_ahead := 200.0
@export var hover_chance := 0.4
@export var max_hover := 2
# Shot enum value -> relative weight; the four original types are equally likely.
@export var drone_shots: Dictionary = {
	Drone.Shot.ORANGE: 1.0,
	Drone.Shot.YELLOW: 1.0,
	Drone.Shot.CYAN: 1.0,
	Drone.Shot.BEAM: 1.0,
}

@export_group("Battles")
@export var battle_interval := 5.5
@export var cluster_min := 2
@export var cluster_max := 4
@export var pocket_x := 55.0
@export var cluster_x_spread := 14.0
@export var cluster_z_spread := 28.0
@export var cluster_z_min := 100.0
@export var cluster_z_max := 150.0

@export_group("Lasers")
@export var laser_interval := 7.0 # 0 disables road-wide laser spawns.


static func load_zone(zone: String) -> RouteDef:
	var path := "res://minigames/runner/routes/%s.tres" % zone
	if not zone.is_empty() and ResourceLoader.exists(path):
		var def := load(path) as RouteDef
		if def != null:
			return def
	push_warning("Unknown or missing runner zone '%s'; using supply_road." % zone)
	return load("res://minigames/runner/routes/supply_road.tres") as RouteDef
