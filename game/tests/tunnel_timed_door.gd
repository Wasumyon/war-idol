extends "res://tests/tunnel_test.gd"
## Headless check for chamber 2's timed door: the lamp charges the floor switch, the charge
## drains, an empty plate drops the door (crushing, or not, by position), reopening cancels a drop.
## Runs through tunnel_segment.tscn (see tunnel_test.gd).

func phys_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func _ready() -> void:
	run()

func run() -> void:
	await start_segment()
	await load_chamber('res://minigames/tunnel/scenes/chambers/chamber_2.tscn')
	var room = sc
	m._busy = true
	var plate = room.get_node('PuzzlesAndHazards/FloorSwitch')
	var door = room.get_node('PuzzlesAndHazards/Door')
	room.get_node('PuzzlesAndHazards/Guard').set_physics_process(false)
	p.set_physics_process(false)
	p.position = Vector2(900, 0)
	p.set_torch(true)
	p._update_light_area()
	await phys_frames(100)
	ok(plate.is_on and door.is_open, 'full charge opens door')
	p.set_torch(false)
	await phys_frames(6)
	ok(plate.charge < 0.99 and door.is_open, 'charge starts draining immediately')
	await phys_frames(84)
	ok(plate.charge > 0.0 and plate.charge < 0.9 and door.is_open, 'charge drains while door stays open')
	p.position = door.position
	p.set_physics_process(true)
	m.set_god_level(1)
	await phys_frames(180)
	ok(not plate.is_on and not door.is_open and not door._shape.disabled, 'empty plate drops door and restores blocking')
	ok(p.is_dead, 'falling door crushes player underneath')
	m.set_god_level(0)
	p.set_physics_process(false)
	p.position = door.position - Vector2(150, 0)
	p.is_dead = false
	door.open()
	await phys_frames(110)
	door.close()
	await phys_frames(40)
	ok(not p.is_dead, 'standing beside falling door is safe')
	door.open()
	await phys_frames(10)
	door.close()
	await phys_frames(10)
	door.open()
	await phys_frames(110)
	ok(door.is_open and door._shape.disabled and door._lift > 0.99, 'reopening cancels an in-progress drop')
	p.position = Vector2(900, 0)
	p.set_torch(true)
	p._update_light_area()
	await phys_frames(100)
	ok(plate.is_on and door.is_open, 'drained switch can be charged again')
	finish()
