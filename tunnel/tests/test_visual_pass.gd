extends Node
var fails: int = 0
func check(value: bool, label: String) -> void:
	print(('PASS ' if value else 'FAIL ') + label)
	if not value: fails += 1
func _ready() -> void:
	GameManager._busy = true
	var room = load('res://scenes/chambers/chamber_0.tscn').instantiate()
	add_child(room)
	await get_tree().process_frame
	var worms = get_tree().get_nodes_in_group('vent_worms')
	check(worms.size() == 6, 'six staged shaft clusters')
	var count: int = 0
	for w in worms:
		check(not w.visible and is_zero_approx(w.growth), 'no opening worms or rubble: ' + w.name)
		check(w.stalk_count > count, 'stalk density increases: ' + w.name)
		count = w.stalk_count
	check(worms[0].position.y == -3000, 'first knock starts only after 530px clear descent')
	var player = room.get_node('Player')
	var visible_before_depth: bool = false
	while not player.controls_enabled:
		await get_tree().physics_frame
		if player.position.y < -3520:
			for w in worms:
				if w.visible: visible_before_depth = true
	check(not visible_before_depth, 'initial descent stayed completely worm-free')
	check(not player.is_dead and player.is_on_floor(), 'safe landing and control restoration')
	for w in worms: check(w.visible and w.growth > 0.5, 'staged cluster struck: ' + w.name)
	room.queue_free()
	await get_tree().process_frame
	room = load('res://scenes/chambers/chamber_3.tscn').instantiate()
	add_child(room)
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group('guard').size() == 2, 'checkout guard count preserved (two; third absent in source)')
	check(room.get_node('ApproachVent').position.x > 1000, 'searchlight-only entrance before vent layer')
	print('RESULT visual pass failures: ', fails)
	get_tree().quit(1 if fails else 0)
