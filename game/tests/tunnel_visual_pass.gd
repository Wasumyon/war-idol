extends "res://tests/tunnel_test.gd"
## Headless check of the staged worm clusters in chamber 0 and the guard count in chamber 3.
## Runs through tunnel_segment.tscn (see tunnel_test.gd).
func check(value: bool, label: String) -> void:
	ok(value, label)
func _ready() -> void:
	await start_segment()
	await load_chamber('res://minigames/tunnel/scenes/chambers/chamber_0.tscn')
	var room = sc
	m._busy = true
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
	m._busy = false
	await load_chamber('res://minigames/tunnel/scenes/chambers/chamber_3.tscn')
	room = sc
	check(get_tree().get_nodes_in_group('guard').size() == 2, 'checkout guard count preserved (two; third absent in source)')
	check(room.get_node('ApproachVent').position.x > 1000, 'searchlight-only entrance before vent layer')
	finish()
