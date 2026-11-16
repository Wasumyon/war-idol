extends PanelContainer

const OBJECTIVE_DURATION: float = 5.0
const FADE_DURATION: float = 0.4


func _ready() -> void:
	hide()
	if GameManager.has_checkpoint:
		queue_free()
		return
	while GameManager.is_transitioning():
		await get_tree().process_frame
	show()
	_style_bubble(self, "I’ve gotta find Chip!\nShe’s gotta be down one of these tunnels…", OBJECTIVE_DURATION)


static func show_line(speaker: Node2D, line: String, duration: float, bubble_name: String,
		offset: Vector2 = Vector2(24, -239)) -> void:
	var bubble: PanelContainer = PanelContainer.new()
	bubble.name = bubble_name
	speaker.add_child(bubble)
	_style_bubble(bubble, line, duration)
	bubble.position = offset


static func _style_bubble(bubble: PanelContainer, line: String, duration: float) -> void:
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a1713")
	style.border_color = Color("#776750")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0

	bubble.position = Vector2(24, -239)
	bubble.z_as_relative = false
	bubble.z_index = 6
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.material = unshaded
	bubble.add_theme_stylebox_override("panel", style)

	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(6, 0), Vector2(21, 0), Vector2(-14, 17)])
	tail.color = style.border_color
	tail.use_parent_material = true
	bubble.add_child(tail)
	bubble.resized.connect(func() -> void: tail.position.y = bubble.size.y - 1)

	var dialogue := Label.new()
	dialogue.text = line
	dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue.use_parent_material = true
	dialogue.add_theme_color_override("font_color", Color("#f0dfc1"))
	dialogue.add_theme_font_size_override("font_size", 19)
	bubble.add_child(dialogue)

	var fade := bubble.create_tween()
	fade.tween_interval(duration)
	fade.tween_property(bubble, "modulate:a", 0.0, FADE_DURATION)
	fade.tween_callback(bubble.queue_free)
