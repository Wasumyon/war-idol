extends Node
## The runner as a calendar segment. Wraps slice.tscn behind the segment contract:
## begin({route, zone}) before entering the tree, then finished({outcome, followers, money}).
## Never changes scene, advances the day or writes the save; MainGame applies results.

signal finished(result: Dictionary)

const SLICE := preload("res://runner/slice.tscn")
const KEYS := {
	&"turnLeft": [KEY_A, KEY_LEFT],
	&"turnRight": [KEY_D, KEY_RIGHT],
	&"accelerate": [KEY_W, KEY_UP],
	&"brake": [KEY_DOWN],
	&"jump": [KEY_SPACE],
}

var _args := {}
var _slice: Node
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
	_start_slice()


## Frees the current run and starts a fresh one. Nothing outside this node reloads.
func restart() -> void:
	if _done:
		return
	if _slice != null:
		_slice.queue_free()
		remove_child(_slice)
	_start_slice()


func _start_slice() -> void:
	_slice = SLICE.instantiate()
	add_child(_slice)


## Ends the segment with the current run's result. Only valid once the run is over.
func continue_run() -> void:
	if _done or _slice == null or _slice.run_active:
		return
	_done = true
	finished.emit({
		"outcome": "bad" if _slice.shields <= 0 else "good",
		"followers": int(_slice.followers),
		"money": int(_slice.money),
	})


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_R:
		restart()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		continue_run()
