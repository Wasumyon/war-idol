extends Node

var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var player: Player = load("res://player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	var sprite: AnimatedSprite2D = player.get_node("Visual/Body/Sprite")
	var lantern: Sprite2D = player.get_node("Visual/Body/Lantern")
	var light: PointLight2D = player.get_node("Visual/TorchLight")
	player.set_torch(false)
	player._update_visual(0.0)
	check(sprite.animation == &"idle" and not lantern.visible, "Lamp off uses original idle")
	player.set_torch(true)
	for facing in [1, -1]:
		player.facing = facing
		for clip in [&"torch_idle", &"torch_walk", &"torch_sprint"]:
			player.velocity = Vector2.ZERO if clip == &"torch_idle" else Vector2(160, 0)
			player.is_sprinting = clip == &"torch_sprint"
			player._update_visual(0.0)
			check(sprite.animation == clip and lantern.visible, "Lit pose %s facing %d" % [clip, facing])
			for frame in sprite.sprite_frames.get_frame_count(clip):
				sprite.frame = frame
				var point: Vector2 = Player.TORCH_HANDS[clip][frame]
				check(lantern.position.is_equal_approx((point + sprite.offset) * sprite.scale), "Hand anchor")
				var glow: Polygon2D = player.get_node("Visual/Body/LampGlow")
				check(light.global_position.is_equal_approx(glow.global_position), "Light follows lens")
				check(player.get_node("Visual/TorchLight/LightArea").global_position.is_equal_approx(light.global_position), "Sensor follows lens")
	player.is_sprinting = false
	player.velocity = Vector2.ZERO
	player.set_hidden(true)
	player._update_visual(0.0)
	check(not player.is_torch_on and not lantern.visible and sprite.animation == &"hide", "Hiding shields lantern")
	player.set_hidden(false)
	await get_tree().create_timer(0.2).timeout
	player._update_visual(0.0)
	check(player.is_torch_on and lantern.visible and sprite.animation == &"torch_idle", "Leaving hiding restores raised lantern")
	player.anim_override = &"fall"
	player._update_visual(0.0)
	check(sprite.animation == &"fall" and not lantern.visible, "Cutscene animation wins")
	print("TORCH SPRITES: %d/%d passed" % [checks - failures, checks])
	player.queue_free()
	if "--torch-preview" in OS.get_cmdline_user_args():
		await preview()
	get_tree().quit(1 if failures else 0)

func preview() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(840, 420)
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var background := ColorRect.new()
	background.size = Vector2(840, 420)
	background.color = Color("292b30")
	viewport.add_child(background)
	for side in 2:
		for pose in 3:
			var p: Player = load("res://player.tscn").instantiate()
			viewport.add_child(p)
			p.set_physics_process(false)
			p.set_process(false)
			p.position = Vector2(120 + pose * 280, 185 + side * 205)
			p.scale = Vector2(1.5, 1.5)
			p.facing = 1 if side == 0 else -1
			p.velocity = Vector2.ZERO if pose == 0 else Vector2(160, 0)
			p.is_sprinting = pose == 2
			p.set_torch(true)
			p._update_visual(0.0)
			p.get_node("Visual/TorchLight").enabled = false
			p.get_node("PresenceLight").enabled = false
			p.get_node("Visual/Body/Sprite").pause()
			var label := Label.new()
			label.text = ["IDLE", "WALK", "RUN"][pose]
			label.position = Vector2(96 + pose * 280, 190 + side * 205)
			viewport.add_child(label)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://build/lantern_pose_preview.png")
