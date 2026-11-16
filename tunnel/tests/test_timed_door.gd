extends SceneTree
var failures: int = 0
func check(value: bool, label: String) -> void:
	print(('PASS ' if value else 'FAIL ') + label)
	if not value: failures += 1
func frames(count: int) -> void:
	for i in count: await physics_frame
func _initialize() -> void:
	call_deferred('run')
func run() -> void:
	var room = load('res://scenes/chambers/chamber_2.tscn').instantiate()
	root.add_child(room)
	await process_frame
	root.get_node('GameManager')._busy = true
	var p = room.get_node('Player')
	var plate = room.get_node('PuzzlesAndHazards/FloorSwitch')
	var door = room.get_node('PuzzlesAndHazards/Door')
	room.get_node('PuzzlesAndHazards/Guard').set_physics_process(false)
	p.set_physics_process(false)
	p.position = Vector2(900, 0)
	p.set_torch(true)
	p._update_light_area()
	await frames(100)
	check(plate.is_on and door.is_open, 'full charge opens door')
	p.set_torch(false)
	await frames(6)
	check(plate.charge < 0.99 and door.is_open, 'charge starts draining immediately')
	await frames(84)
	check(plate.charge > 0.0 and plate.charge < 0.9 and door.is_open, 'charge drains while door stays open')
	p.position = door.position
	p.set_physics_process(true)
	root.get_node('GameManager').set_god_level(1)
	await frames(180)
	check(not plate.is_on and not door.is_open and not door._shape.disabled, 'empty plate drops door and restores blocking')
	check(p.is_dead, 'falling door crushes player underneath')
	root.get_node('GameManager').set_god_level(0)
	p.set_physics_process(false)
	p.position = door.position - Vector2(150, 0)
	p.is_dead = false
	door.open()
	await frames(110)
	door.close()
	await frames(40)
	check(not p.is_dead, 'standing beside falling door is safe')
	door.open()
	await frames(10)
	door.close()
	await frames(10)
	door.open()
	await frames(110)
	check(door.is_open and door._shape.disabled and door._lift > 0.99, 'reopening cancels an in-progress drop')
	p.position = Vector2(900, 0)
	p.set_torch(true)
	p._update_light_area()
	await frames(100)
	check(plate.is_on and door.is_open, 'drained switch can be charged again')
	quit(1 if failures else 0)
