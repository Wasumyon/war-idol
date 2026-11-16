extends Node
## Diagnostic scene only. Run with a real renderer; headless timings are not GPU evidence.
## Export this scene as a temporary web main scene to repeat the same cases in-browser.
var room: Node

func _ready() -> void:
	GameManager._busy = true
	GameManager.set_invincibility(true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for spot in [{"name": "entrance", "x": 100.0}, {"name": "wall", "x": 1080.0}, {"name": "pool", "x": 2100.0}]:
		for mode in ["full", "no_lights", "no_worm_visuals", "no_acid_visuals"]:
			room = load("res://scenes/chambers/chamber_1.tscn").instantiate()
			add_child(room)
			await get_tree().process_frame
			var player: Player = room.get_node("Player")
			player.controls_enabled = false
			player.position.x = spot.x
			var camera: Camera2D = room.get_node("MainCamera")
			camera.position = player.position + Vector2(0, -130)
			camera.reset_smoothing()
			for node in room.find_children("*", "", true, false):
				if mode == "no_lights" and node is PointLight2D:
					node.enabled = false
				elif mode == "no_worm_visuals" and node is TubewormCluster:
					node.hide()
				elif mode == "no_acid_visuals" and node is AcidPool:
					node.hide()
			await get_tree().create_timer(1.0).timeout
			var samples: Array[float] = []
			var draw_calls: float = 0.0
			var process_ms: float = 0.0
			var start: int = Time.get_ticks_usec()
			var previous: int = start
			while Time.get_ticks_usec() - start < 2000000:
				await get_tree().process_frame
				var now: int = Time.get_ticks_usec()
				samples.append((now - previous) / 1000.0)
				previous = now
				draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			samples.sort()
			var count: int = samples.size()
			print("CH1_PROFILE spot=%s mode=%s frames=%d frame_ms_median=%.3f frame_ms_p95=%.3f process_ms_mean=%.3f draw_calls_mean=%.1f" % [spot.name, mode, count, samples[count / 2], samples[mini(count - 1, int(count * 0.95))], process_ms / count, draw_calls / count])
			room.queue_free()
			await get_tree().process_frame
	print("CH1_PROFILE complete; compare within the same device/browser, with the tab foregrounded.")
	get_tree().quit()
