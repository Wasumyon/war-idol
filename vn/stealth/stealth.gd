extends Node3D
## The stealth minigame's segment root (stealth_spec.md §9). begin(args) before it enters the
## tree, then finished(result) at the map's exit. It never changes scene, advances the day or
## writes the save. Opened on its own (F6) it loads the test map.

signal finished(result: Dictionary)

const DEFAULT_MAP := "res://stealth/maps/test_map.tscn"
const MAP_DIR := "res://stealth/maps/%s.tscn"
const PLAYER_SCENE := preload("res://stealth/player.tscn")

## Keys, registered as input actions at load. Physical keycodes.
const KEYS := {
	&"stealth_up": [KEY_W, KEY_UP],
	&"stealth_down": [KEY_S, KEY_DOWN],
	&"stealth_left": [KEY_A, KEY_LEFT],
	&"stealth_right": [KEY_D, KEY_RIGHT],
	&"stealth_crouch": [KEY_CTRL, KEY_C],
	&"stealth_camera": [KEY_V],
	&"stealth_debug_noise": [KEY_N],
}
const HINT := "WASD move   Ctrl/C crouch   V camera   N test noise"

var map: Node3D
var player: CharacterBody3D

var _args := {}
var _done := false
var _checkpoint_pos := Vector3.ZERO
var _checkpoint_zone: Node3D

@onready var _rig: Node3D = $CameraRig
@onready var _map_slot: Node3D = $MapSlot
@onready var _status: Label = $Overlay/Status
@onready var _hint: Label = $Overlay/Hint
@onready var _flash: ColorRect = $Overlay/Flash


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
	var path := str(_args.get("map", DEFAULT_MAP))
	if not path.begins_with("res://"):
		path = MAP_DIR % path
	map = (load(path) as PackedScene).instantiate()
	_map_slot.add_child(map)
	player = PLAYER_SCENE.instantiate()
	map.add_child(player)
	_checkpoint_pos = map.start_position()
	player.teleport(_checkpoint_pos)
	_rig.target = player
	_rig.snap_to_target()
	_hint.text = HINT
	_hint.visible = OS.is_debug_build()
	_flash.modulate.a = 0.0
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed(&"stealth_camera"):
		_rig.toggle()


func _physics_process(_delta: float) -> void:
	if _done:
		return
	player.move_yaw = _rig.yaw()
	var pos := player.global_position
	var zone: Node3D = map.checkpoint_at(pos)
	if zone and zone != _checkpoint_zone:
		_set_checkpoint(zone)
	if map.is_exit(pos):
		_finish()
	_update_status()


func _set_checkpoint(zone: Node3D) -> void:
	if _checkpoint_zone:
		_checkpoint_zone.set_active(false)
	_checkpoint_zone = zone
	_checkpoint_pos = zone.global_position
	zone.set_active(true)


func _finish() -> void:
	_done = true
	player.frozen = true
	_update_status()
	finished.emit(_result())


func _result() -> Dictionary:
	return {"outcome": "clean"}


func _update_status() -> void:
	_status.text = "EXIT REACHED   %s" % [_result()] if _done else ""
