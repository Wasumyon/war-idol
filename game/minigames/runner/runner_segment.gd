extends Node
## The runner as a calendar segment. Wraps run.tscn behind the segment contract:
## begin({route, zone, seed?}) before entering the tree, then finished({outcome, followers, money}).
## Never changes scene, advances the day or writes the save; Main applies results.

signal finished(result: Dictionary)

const RUN := preload("res://minigames/runner/run.tscn")
const KEYS := {
	&"turnLeft": [KEY_A, KEY_LEFT],
	&"turnRight": [KEY_D, KEY_RIGHT],
	&"accelerate": [KEY_W, KEY_UP],
	&"brake": [KEY_DOWN],
	&"jump": [KEY_SPACE],
}

var _args := {}
var _run: Node
var _done := false


func _init() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func begin(args: Dictionary) -> void:
	_args = args


func _ready() -> void:
	_start_run()


## Frees the current run and starts a fresh one. Nothing outside this node reloads.
func restart() -> void:
	if _done:
		return
	if _run != null:
		_run.queue_free()
		remove_child(_run)
	_start_run()


func _start_run() -> void:
	_run = RUN.instantiate()
	_run.route_def = RouteDef.load_zone(str(_args.get("zone", "")))
	var generator := RandomNumberGenerator.new()
	if _args.has("seed"):
		generator.seed = int(_args.seed)
	else:
		generator.randomize()
	_run.rng = generator
	add_child(_run)


## Ends the segment with the current run's result. Only valid once the run is over.
func continue_run() -> void:
	if _done or _run == null or _run.run_active:
		return
	_done = true
	finished.emit({
		"outcome": "bad" if _run.shields <= 0 else "good",
		"followers": int(_run.followers),
		"money": int(_run.money),
	})


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_R:
		restart()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		continue_run()
