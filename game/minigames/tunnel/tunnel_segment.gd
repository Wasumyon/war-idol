extends Node
## Tunnel Escape as a calendar segment. begin({start, ending}) before entering the tree,
## then finished({outcome: "escaped", deaths}). Never changes scene, advances the day or
## writes the save; Main applies results.
##
##   start:  "chamber_0" (default) | "intro"     where the run opens
##   ending: "none" (default) | "sequence"      "none" finishes as the player walks into the
##                                               last room; "sequence" plays tunnel's own ending first
##
## The tunnel was built for a 1280x720 canvas, so it runs inside a SubViewport with that
## canvas, sized to the window's real pixels so it stays sharp in the 960x540 game. The
## chamber slot holds one chamber (or the intro) at a time; TunnelManager swaps it.
##
## Esc: tunnel's own pause menu (pause_menu.gd, inside the viewport) takes it. This root
## then swallows Esc so Main's pause, which reads it last, never opens on top.

signal finished(result: Dictionary)

const INTRO := "res://minigames/tunnel/scenes/intro.tscn"
const CHAMBER_0 := "res://minigames/tunnel/scenes/chambers/chamber_0.tscn"
const CANVAS := Vector2i(1280, 720)
## Tunnel's own actions, added once and left in place (as runner_segment.gd does).
const KEYS := {
	&"interact": [KEY_E],
	&"sprint": [KEY_SHIFT],
	&"action_torch": [KEY_SPACE],
	&"action_hide": [KEY_W, KEY_UP],
	&"restart": [KEY_R],
}
## Added to the shared ui_left / ui_right only while the tunnel is in the tree.
const UI_KEYS := {&"ui_left": KEY_A, &"ui_right": KEY_D}

var start := "chamber_0"
var ending := "none"

@onready var _screen: SubViewportContainer = $Screen
@onready var _viewport: SubViewport = $Screen/Viewport
@onready var _manager: TunnelManager = $Screen/Viewport/Manager
@onready var _slot: Node = $Screen/Viewport/ChamberSlot

var _added_ui: Array[Array] = []  ## [action, event] pairs this node added
var _done := false


func _init() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.2)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func begin(args: Dictionary) -> void:
	start = str(args.get("start", start))
	ending = str(args.get("ending", ending))
	if start not in ["intro", "chamber_0"]:
		push_error("TunnelSegment: unknown start %s, using chamber_0" % start)
		start = "chamber_0"
	if ending not in ["sequence", "none"]:
		push_error("TunnelSegment: unknown ending %s, using none" % ending)
		ending = "none"


func _enter_tree() -> void:
	for action: StringName in UI_KEYS:
		if not InputMap.has_action(action):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = UI_KEYS[action]
		if InputMap.action_has_event(action, event):
			continue
		InputMap.action_add_event(action, event)
		_added_ui.append([action, event])


func _exit_tree() -> void:
	for pair: Array in _added_ui:
		if InputMap.has_action(pair[0]):
			InputMap.action_erase_event(pair[0], pair[1])
	_added_ui.clear()


func _ready() -> void:
	# The pause menu, fades and music keep running while the tunnel pauses the tree;
	# the chamber slot alone freezes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_slot.process_mode = Node.PROCESS_MODE_PAUSABLE
	_viewport.size_2d_override = CANVAS
	_viewport.size_2d_override_stretch = true
	_viewport.audio_listener_enable_2d = true
	get_tree().root.size_changed.connect(_fit)
	_fit()
	_manager.slot = _slot
	_manager.ending = ending
	_manager.escaped.connect(_on_escaped)
	_manager.start(INTRO if start == "intro" else CHAMBER_0)


## Size the viewport to the real pixels the game's canvas covers, then scale the container
## back down so it fills that canvas exactly: no resampling, so the tunnel stays sharp.
func _fit() -> void:
	var window := get_window()
	var base := Vector2(window.content_scale_size)
	if base.x <= 0.0 or base.y <= 0.0:
		base = get_viewport().get_visible_rect().size
	var real := Vector2(window.size)
	var f := minf(real.x / base.x, real.y / base.y)
	if f <= 0.0 or is_nan(f):
		f = 1.0
	_screen.position = Vector2.ZERO
	_screen.size = (base * f).round()
	_screen.scale = Vector2.ONE / f


func _unhandled_input(event: InputEvent) -> void:
	# Tunnel's pause menu has already seen Esc inside the viewport; keep it from Main's.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _on_escaped() -> void:
	if _done:
		return
	_done = true
	if get_tree().paused:
		get_tree().paused = false
	var result := {"outcome": "escaped", "deaths": _manager.death_count}
	if finished.get_connections().is_empty():
		# Run on its own (F6): nobody is listening, so go round again.
		print("TunnelSegment finished: ", result, " (no listener; restarting)")
		_done = false
		_manager.restart_run(INTRO if start == "intro" else CHAMBER_0)
		return
	finished.emit(result)
