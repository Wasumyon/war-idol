extends Node3D
## One noise (docs/stealth_spec.md §3): a red dashed outline on the floor with a sound symbol,
## centred on its source. fire() sends a soft white ring out to the outline; each guard
## inside is alerted as the ring reaches him and walks to the centre. Guards outside are
## unaffected. Add it, place it, then fire it; before fire() it is only the outline, which
## is what aim mode will show.

const Draw := preload("res://stealth/draw.gd")

const OUTLINE_COLOR := Color(1.0, 0.2, 0.15, 0.9)
const RING_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const SYMBOL := "((!))"

@export var radius := 6.0
@export var ring_time := 0.5      ## seconds for the ring to reach the outline
@export var linger_time := 1.0    ## seconds the outline stays after that
@export var outline_width := 0.1
@export var dash_count := 28

var _guards: Array = []
var _alerted := {}
var _time := -1.0
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D


func _ready() -> void:
	add_to_group(&"stealth_noise")
	var outline := Draw.mesh_instance(
		Draw.ring_mesh(radius, outline_width, 64, dash_count), Draw.flat_material(OUTLINE_COLOR))
	outline.position.y = 0.07
	add_child(outline)
	_ring_mat = Draw.flat_material(RING_COLOR)
	_ring = Draw.mesh_instance(Draw.ring_mesh(1.0, 0.04), _ring_mat)
	_ring.position.y = 0.09
	_ring.visible = false
	add_child(_ring)
	var symbol := Label3D.new()
	symbol.text = SYMBOL
	symbol.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbol.no_depth_test = true
	symbol.pixel_size = 0.015
	symbol.font_size = 48
	symbol.outline_size = 12
	symbol.modulate = OUTLINE_COLOR
	symbol.position.y = 0.6
	add_child(symbol)


## The guards this noise would alert: inside the outline and not knocked out.
func guards_inside(guards: Array) -> Array:
	return guards.filter(func(guard: Node3D) -> bool:
		return not guard.is_knocked_out() and _flat_distance(guard) <= radius)


func fire(guards: Array) -> void:
	_guards = guards_inside(guards)
	_time = 0.0
	_ring.visible = true


func _physics_process(delta: float) -> void:
	if _time < 0.0:
		return
	_time += delta
	var reach := radius * minf(_time / ring_time, 1.0)
	_ring.scale = Vector3(maxf(reach, 0.01), 1.0, maxf(reach, 0.01))
	for guard: Node3D in _guards:
		if not _alerted.has(guard) and is_instance_valid(guard) and _flat_distance(guard) <= reach:
			_alerted[guard] = true
			guard.hear_noise(global_position)
	if _time > ring_time:
		_ring_mat.albedo_color.a = RING_COLOR.a * (1.0 - (_time - ring_time) / linger_time)
	if _time > ring_time + linger_time:
		queue_free()


func _flat_distance(node: Node3D) -> float:
	var to := node.global_position - global_position
	return Vector2(to.x, to.z).length()
