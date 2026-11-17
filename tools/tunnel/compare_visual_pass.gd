extends Node
var samples: Array[float] = []
func _ready() -> void:
	GameManager._busy = true
	GameManager.set_invincibility(true)
	for room_id in [1, 3, 4]:
		for baseline in [true, false]:
			var path = ('res://build/visual-pass-before/scenes/chambers/' if baseline else 'res://scenes/chambers/') + 'chamber_%d.tscn' % room_id
			var room = load(path).instantiate()
			add_child(room)
			await get_tree().process_frame
			var player = room.find_child('Player', true, false)
			player.controls_enabled = false
			player.position.x = 1080 if room_id == 1 else (250 if room_id == 3 else 1000)
			for worm in room.find_children('*', '', true, false):
				if baseline and worm is TubewormCluster:
					worm.redraw_fps = 0.0
					worm.curve_segments = 10
					worm.plume_feathers = 9
					worm.cull_offscreen_drawing = false
			for frame in 60: await get_tree().process_frame
			samples.clear()
			var calls: float = 0.0
			for frame in 180:
				await get_tree().process_frame
				samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
				calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			var total: float = 0.0
			for sample in samples: total += sample
			samples.sort()
			print('COMPARE room=%d baseline=%s process_ms_mean=%.3f p95=%.3f draw_calls=%.1f' % [room_id, baseline, total / samples.size(), samples[170], calls / 180.0])
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png('res://build/visual-room%d-%s.png' % [room_id, 'before' if baseline else 'after'])
			room.queue_free()
			await get_tree().process_frame
	get_tree().quit()
