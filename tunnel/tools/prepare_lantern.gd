extends SceneTree

func _initialize() -> void:
	var image := Image.load_from_file("res://art/sprites/mc/lantern.png")
	var cropped := image.get_region(Rect2i(220, 170, 1160, 660))
	cropped.resize(116, 66, Image.INTERPOLATE_LANCZOS)
	cropped.save_png("res://art/sprites/mc/lantern_2d.png")
	print("LANTERN PREPARED")
	quit()
