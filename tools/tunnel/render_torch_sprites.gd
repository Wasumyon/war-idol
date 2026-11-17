extends SceneTree
## Render the model's existing torch clips to transparent 256x240 sprite sheets.

func _initialize() -> void:
	call_deferred("render_sprites")

func render_sprites() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 240)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var model: Node3D = load("res://art/player/Model/mainguy.glb").instantiate()
	viewport.add_child(model)
	var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var material := StandardMaterial3D.new()
		material.albedo_texture = load("res://art/player/Model/diffuse.png")
		material.roughness = 0.85
		child.material_override = material
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	viewport.add_child(camera)
	camera.position = Vector3(-5, 1.08, 0)
	camera.look_at(Vector3(0, 1.08, 0))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -65, 0)
	key.light_energy = 1.0
	viewport.add_child(key)
	var hand := skeleton.find_bone("mixamorig_LeftHand")
	var metadata := {}
	for clip in {"torch_idle": "Torch Idle", "torch_walk": "Torch Walk Forward", "torch_sprint": "Torch Run Forward"}:
		var clip_name: String = {"torch_idle": "Torch Idle", "torch_walk": "Torch Walk Forward", "torch_sprint": "Torch Run Forward"}[clip]
		var count := ceili(animation.get_animation(clip_name).length * 24.0)
		var sheet := Image.create(2048, ceili(count / 8.0) * 240, false, Image.FORMAT_RGBA8)
		var hands := []
		animation.play(clip_name)
		animation.pause()
		for frame in count:
			animation.seek(float(frame) / 24.0, true)
			await process_frame
			await RenderingServer.frame_post_draw
			var point := camera.unproject_position(skeleton.to_global(skeleton.get_bone_global_pose(hand).origin))
			hands.append([snappedf(point.x, 0.01), snappedf(point.y, 0.01)])
			sheet.blit_rect(viewport.get_texture().get_image(), Rect2i(0, 0, 256, 240), Vector2i((frame % 8) * 256, (frame / 8) * 240))
		var path: String = "res://art/sprites/mc/model/mc_%s.png" % clip
		sheet.save_png(path)
		metadata[clip] = {"frames": count, "fps": 24, "hands": hands}
		print("RENDERED ", clip, " ", count, " frames")
	var file := FileAccess.open("res://art/sprites/mc/model/torch_hands.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "\t"))
	quit()
