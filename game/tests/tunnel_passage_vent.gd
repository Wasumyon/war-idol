extends "res://tests/tunnel_test.gd"
## Headless check for the chamber 2 passage vent. Runs through tunnel_segment.tscn.

func wait_real(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _ready() -> void:
	await start_segment()
	await load_chamber("res://minigames/tunnel/scenes/chambers/chamber_2.tscn")
	var room: Node = sc
	m.god_mode = true
	var vent: Node = room.get_node("PuzzlesAndHazards/PassageVent")
	var guard: EnemyGuard = room.get_node("PuzzlesAndHazards/Guard")
	var player: Player = room.get_node("Player")
	player.controls_enabled = false
	guard.set_physics_process(false)
	guard.global_position.x = 2400.0
	await wait_real(0.15)
	ok(vent.phase == 0, "quiet vent stays hidden")
	# Move a lit player near the vent: illumination must not suppress the warning.
	player.global_position.x = 1290.0
	player.set_torch(true)
	var light: Area2D = Area2D.new()
	light.collision_layer = 4
	light.collision_mask = 0
	light.add_to_group("light_source")
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 100.0
	shape.shape = circle
	light.add_child(shape)
	vent.add_child(light)
	await wait_real(0.12)
	ok(vent.phase == 1, "lit footsteps trigger warning")
	player.global_position.x = 1650.0
	await wait_real(0.58)
	ok(vent.phase == 2, "warning leads to strike")
	await wait_real(0.4)
	ok(vent.phase == 3, "light accelerates retraction after the strike")
	await wait_real(3.1)
	ok(vent.phase == 0, "vent rearms after cooldown")
	guard.global_position.x = 1610.0
	guard.state = EnemyGuard.State.WALK
	guard._set_facing(-1)
	guard.set_physics_process(true)
	await wait_real(0.2)
	ok(guard._vent_sprint > 0.0, "guard reacts to vent rattle")
	await wait_real(0.45)
	ok(guard.global_position.x < 1470.0, "guard hurries through vent approach")
	ok(guard.state != EnemyGuard.State.CHARGE, "vent sprint does not start a player chase")
	finish()
