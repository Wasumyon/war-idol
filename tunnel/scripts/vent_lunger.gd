class_name VentLunger
extends Node2D
## A vent worm living behind the back wall of the shaft, like a grate eel. It knocks behind
## the grate as he falls toward it, then pops a short way out *toward the screen*, snaps its
## plume-jaws a couple of times and ducks back in, a moment too late: he's already fallen past.
## Harmless; foreshadowing for the Ch 5 vent.
##
## Node origin = the hole in the back wall. The hole and grate are drawn in the world
## (in the dark); the lunging body is drawn on its own CanvasLayer above the world so it
## reads as close to the camera, with its own light level.

@export var hole_radius: float = 20.0
## Radius on screen of the worm's head when fully out (a little bigger than the hole: it's
## only poking a short way toward you).
@export var tip_radius: float = 30.0
## How much the lunge drifts away from the screen centre as it nears the camera (0 = straight at you).
@export var drift: float = 0.0
## Brightness of the nearest part of the body (it isn't under the room's darkness).
@export var near_brightness: float = 0.5
@export var random_seed: int = 3

## 0 = inside the wall, 1 = fully lunged at the camera.
var extension: float = 0.0
## 0..1 grate rattle while it knocks.
var rattle: float = 0.0
## 0..1 how far its plume-jaws are open (it snaps them while it's out).
var jaws: float = 0.0

var _time: float = 0.0
var _layer: CanvasLayer
var _body: Node2D
var _tween: Tween
var _phase: float = 0.0

const BONE: Color = Color(0.90, 0.87, 0.80)
const PLUME: Color = Color(0.72, 0.07, 0.10)
const MAW: Color = Color(0.12, 0.02, 0.03)


func _ready() -> void:
	add_to_group("vent_lungers")
	_phase = float(random_seed) * 1.7
	_layer = CanvasLayer.new()
	_layer.layer = 5  # above the world, under the HUD vignette
	_layer.follow_viewport_enabled = true
	add_child(_layer)
	_body = Node2D.new()
	_body.draw.connect(_draw_lunge)
	_layer.add_child(_body)


func _process(delta: float) -> void:
	_time += delta
	rattle = move_toward(rattle, 0.0, delta * 2.5)
	queue_redraw()
	_body.queue_redraw()


## Thumping behind the grate; the plumes peek out of the hole.
func knock(strength: float = 1.0) -> void:
	rattle = clampf(0.6 + 0.4 * strength, 0.0, 1.0)
	_go([[0.25, 0.08], [0.0, 0.16], [0.0, 0.1], [0.35, 0.07], [0.0, 0.2]])


## Pops out at the camera, snaps twice, ducks back into the grate.
func strike() -> void:
	rattle = 1.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "extension", 1.0, 0.11)
	_tween.parallel().tween_property(self, "jaws", 1.0, 0.11)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i: int in 2:
		_tween.tween_property(self, "jaws", 0.0, 0.07)  # snap
		_tween.tween_property(self, "jaws", 1.0, 0.12)
	_tween.tween_property(self, "jaws", 0.0, 0.07)
	_tween.tween_interval(0.08)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "extension", 0.0, 0.22)


func _go(steps: Array) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	for s: Array in steps:
		_tween.tween_property(self, "extension", s[0], s[1])


# ---- the hole in the back wall (in the world, lit like the room)
func _draw() -> void:
	var shake: Vector2 = Vector2(sin(_time * 70.0), cos(_time * 63.0)) * rattle * 4.0
	draw_circle(shake, hole_radius + 9.0, Color(0.16, 0.16, 0.18))
	draw_circle(shake, hole_radius, Color(0.02, 0.02, 0.025))
	# grate bars, bent outward once it has burst through
	var bent: float = clampf(extension * 3.0, 0.0, 1.0)
	for i: int in 3:
		var y: float = (float(i) - 1.0) * hole_radius * 0.55
		var half: float = sqrt(maxf(hole_radius * hole_radius - y * y, 0.0))
		var mid: Vector2 = shake + Vector2(0.0, y - bent * 10.0 * (1.0 - absf(float(i) - 1.0) * 0.5))
		draw_polyline(PackedVector2Array([shake + Vector2(-half, y), mid, shake + Vector2(half, y)]),
				Color(0.32, 0.32, 0.34), 3.0, true)
	draw_arc(shake, hole_radius + 4.0, 0.0, TAU, 28, Color(0.36, 0.36, 0.38), 3.0, true)


# ---- the lunge (on its own layer, so it reads as in front of the back wall)
## Drawn like the side-wall worms' crowns: a tuft of crimson plumes that bursts out of
## the grate, droops a little, and clamps shut into a point when it snaps. No pale disc:
## you only glimpse the pale stalk inside the hole.
func _draw_lunge() -> void:
	if extension < 0.02:
		return
	var hole: Vector2 = global_position
	var lum: float = lerpf(0.3, near_brightness, extension)
	var wob: Vector2 = Vector2(sin(_time * 13.0 + _phase), cos(_time * 11.0 + _phase)) * 1.5 * extension
	var tip: Vector2 = hole + Vector2(0.0, 3.0 * extension) + wob
	# glimpse of the stalk end in the hole
	var bone: Color = BONE * lum * 0.8
	bone.a = 1.0
	_body.draw_circle(tip, hole_radius * 0.38 * extension, bone)
	var open: float = jaws * clampf(extension * 2.0, 0.0, 1.0)
	var reach: float = tip_radius * extension
	var pc: Color = PLUME * (lum * 1.4)
	pc.a = 1.0
	var tipc: Color = PLUME.lightened(0.2) * (lum * 1.4)
	tipc.a = 1.0
	var n: int = 11
	for i: int in n:
		var t: float = float(i) / float(n - 1) * 2.0 - 1.0
		# open: a fan spread wide (heavier toward the bottom, drooping);
		# shut: every plume clamps toward one point straight out at you
		var a: float = PI * 0.5 + t * lerpf(0.25, 2.6, open) + sin(_time * 7.0 + float(i) * 1.3) * 0.08
		var dir: Vector2 = Vector2(cos(a), sin(a) * 0.85)
		var len: float = reach * lerpf(0.45, 1.0, open) * (0.8 + 0.2 * sin(float(i) * 2.1 + _phase))
		var end: Vector2 = tip + dir * len
		var bend: Vector2 = tip + dir.rotated(0.25 * t) * len * 0.55
		_body.draw_polyline(PackedVector2Array([tip, bend, end]), pc, 2.0, true)
		_body.draw_circle(end, 1.8, tipc)
	_body.draw_circle(tip, 2.5 + 2.5 * open, MAW)
