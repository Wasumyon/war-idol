extends SceneTree
## Offline orthographic bake; no 3D rendering is needed during gameplay.

func _initialize() -> void:
	call_deferred("render_sprites")

func render_sprites() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var model: Node3D = load("res://art/enemies/Model/guard1.glb").instantiate()
	viewport.add_child(model)
	var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var material := StandardMaterial3D.new()
		material.albedo_texture = load("res://art/enemies/Model/Guard_Diffuse.png")
		material.roughness = 0.9
		mesh.material_override = material
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.3
	viewport.add_child(camera)
	camera.position = Vector3(-5, 1.03, 0)
	camera.look_at(Vector3(0, 1.03, 0))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -65, 0)
	key.light_energy = 1.0
	viewport.add_child(key)
	var clips := ["idle1", "Walk forward", "run_guard"]
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var hips := skeleton.find_bone("mixamorig_Hips")
	var sheet := Image.create(4096, 1024, false, Image.FORMAT_RGBA8)
	var durations := []
	for row in 3:
		var clip: Animation = animation.get_animation(clips[row])
		durations.append(clip.length)
		animation.play(clips[row])
		animation.pause()
		var count: int = 32 if row == 0 else 16
		for frame in count:
			model.position = Vector3.ZERO
			animation.seek(float(frame) / float(count) * clip.length, true)
			skeleton.force_update_all_bone_transforms()
			var root_position := skeleton.to_global(skeleton.get_bone_global_pose(hips).origin)
			model.position = Vector3(-root_position.x, 0, -root_position.z)
			await process_frame
			await RenderingServer.frame_post_draw
			var capture := viewport.get_texture().get_image()
			sheet.blit_rect(capture, Rect2i(0, 0, 256, 256), Vector2i((frame % 16) * 256, (frame / 16 if row == 0 else row + 1) * 256))
		print("RENDERED ", clips[row], " duration ", clip.length)
	sheet.save_png("res://art/sprites/guard/guard_model_animations.png")
	print("DURATIONS ", durations)
	quit()

