class_name GunshotFX
extends Node2D
## One shot: a muzzle flash (light + star) at the gun, a tracer to the target,
## and a quick white kick on screen. Frees itself. No audio yet.
##   GunshotFX.fire(get_tree().current_scene, muzzle_pos, target_pos)

const LIGHT_TEX: Texture2D = preload("res://art/light_radial.tres")

var _t: float = 0.0
var _flash: PointLight2D
var _star: Polygon2D
var _tracer: Line2D
var _screen: ColorRect


static func fire(parent: Node, muzzle: Vector2, target: Vector2) -> GunshotFX:
	var fx: GunshotFX = GunshotFX.new()
	parent.add_child(fx)
	fx._build(muzzle, target)
	return fx


func _build(muzzle: Vector2, target: Vector2) -> void:
	z_index = 6
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	_flash = PointLight2D.new()
	_flash.texture = LIGHT_TEX
	_flash.color = Color(1.0, 0.85, 0.55)
	_flash.energy = 4.0
	_flash.texture_scale = 2.2
	_flash.global_position = muzzle
	add_child(_flash)

	_star = Polygon2D.new()
	_star.material = add
	_star.color = Color(1.0, 0.9, 0.6, 1.0)
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 12:
		var r: float = 26.0 if i % 2 == 0 else 8.0
		var a: float = TAU * float(i) / 12.0 + randf() * 0.2
		pts.append(muzzle + Vector2(cos(a), sin(a)) * r)
	_star.polygon = pts
	add_child(_star)

	_tracer = Line2D.new()
	_tracer.material = add
	_tracer.width = 3.0
	_tracer.default_color = Color(1.0, 0.85, 0.5, 0.9)
	_tracer.points = PackedVector2Array([muzzle, target])
	add_child(_tracer)

	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_screen = ColorRect.new()
	_screen.color = Color(1.0, 0.95, 0.85, 0.35)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_screen)


func _process(delta: float) -> void:
	_t += delta
	_flash.energy = maxf(4.0 * (1.0 - _t / 0.12), 0.0)
	_star.visible = _t < 0.06
	_tracer.default_color.a = maxf(0.9 * (1.0 - _t / 0.18), 0.0)
	_screen.color.a = maxf(0.35 * (1.0 - _t / 0.1), 0.0)
	if _t > 0.4:
		queue_free()
