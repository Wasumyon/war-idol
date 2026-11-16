extends Node3D
## The stealth minigame's segment root (docs/stealth_spec.md §9). begin(args) before it enters the
## tree, then finished(result) at the map's exit. It never changes scene, advances the day or
## writes the save. Opened on its own (F6) it loads the test map.

signal finished(result: Dictionary)

const DEFAULT_MAP := "res://stealth/maps/test_map.tscn"
const MAP_DIR := "res://stealth/maps/%s.tscn"
const PLAYER_SCENE := preload("res://stealth/player.tscn")
const Guard := preload("res://stealth/guard.gd")
const StealthNoise := preload("res://stealth/noise.gd")

## What the visor overlay shows in real time (docs/stealth_spec.md §3). The overlay view (Q)
## always shows everything.
enum OverlayMode { ALWAYS, FACING, AIM_ONLY }

## Keys, registered as input actions at load. Physical keycodes.
const KEYS := {
	&"stealth_up": [KEY_W, KEY_UP],
	&"stealth_down": [KEY_S, KEY_DOWN],
	&"stealth_left": [KEY_A, KEY_LEFT],
	&"stealth_right": [KEY_D, KEY_RIGHT],
	&"stealth_crouch": [KEY_CTRL, KEY_C],
	&"stealth_camera": [KEY_V],
	&"stealth_overlay_view": [KEY_Q],
	&"stealth_overlay_mode": [KEY_O],
	&"stealth_debug_noise": [KEY_N],
}
const HINT := "WASD move   Ctrl/C crouch   Q overlay view   V camera   O overlay: %s   N test noise"

@export var overlay_mode := OverlayMode.FACING
@export_group("Alarm")
## Guards within this distance of where the alarm started join it.
@export var alarm_radius := 20.0
## Seconds with no guard seeing him before an alarm drops to searching.
@export var alarm_lose_time := 4.0
## Each crisis level adds this fraction to how fast detection meters fill.
@export var crisis_step := 0.35
@export var catch_fade_time := 0.6
@export_group("Debug")
## Radius of the test noise the N key fires at the player (debug builds).
@export var debug_noise_radius := 6.0

var crisis_level := 0
var alarms := 0
var catches := 0
var alarm_active := false
var last_seen_pos := Vector3.ZERO
## The stand-in for aim mode: the world is stopped and the whole overlay is drawn.
var overlay_view := false

var map: Node3D
var player: CharacterBody3D

var _args := {}
var _done := false
var _checkpoint_pos := Vector3.ZERO
var _checkpoint_zone: Node3D
var _unseen := 0.0
var _catching := false

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
	for guard in map.guards:
		guard.setup(self, player)
	_hint.visible = OS.is_debug_build()
	_redraw_guards()
	_flash.modulate.a = 0.0
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed(&"stealth_camera"):
		_rig.toggle()
	elif event.is_action_pressed(&"stealth_overlay_view"):
		set_overlay_view(not overlay_view)
	elif event.is_action_pressed(&"stealth_overlay_mode"):
		overlay_mode = ((overlay_mode + 1) % OverlayMode.size()) as OverlayMode
		_redraw_guards()
		_update_status()
	elif event.is_action_pressed(&"stealth_debug_noise") and OS.is_debug_build() \
			and not overlay_view:
		emit_noise(player.global_position, debug_noise_radius)


# --- the director: what guards ask and tell ---

## The one place that decides what the overlay draws now. A Guard.Overlay value.
func overlay_level() -> int:
	if overlay_view or overlay_mode == OverlayMode.ALWAYS:
		return Guard.Overlay.FULL
	return Guard.Overlay.FACING if overlay_mode == OverlayMode.FACING else Guard.Overlay.NONE


## Inside a concealment patch nobody can be seen.
func is_concealed(pos: Vector3) -> bool:
	return map.is_concealed(pos)


## Fires a noise at a point: guards inside its outline walk to the centre.
func emit_noise(pos: Vector3, radius: float) -> Node3D:
	var noise: Node3D = StealthNoise.new()
	noise.radius = radius
	map.add_child(noise)
	noise.global_position = pos
	noise.fire(map.guards)
	return noise


func detection_multiplier() -> float:
	return 1.0 + crisis_level * crisis_step


## A guard's meter is full. One alarm at a time: each new one raises the crisis level.
func raise_alarm(pos: Vector3, by: Node) -> void:
	last_seen_pos = pos
	_unseen = 0.0
	if not alarm_active:
		alarm_active = true
		alarms += 1
		crisis_level += 1
		for guard in map.guards:
			if guard.global_position.distance_to(pos) <= alarm_radius:
				guard.enter_alarm()
	by.enter_alarm()
	_update_status()


func report_sighting(pos: Vector3) -> void:
	last_seen_pos = pos
	_unseen = 0.0


## An alarmed guard reached him: back to the checkpoint, crisis level kept.
func catch_player(_by: Node) -> void:
	if _catching or _done:
		return
	_catching = true
	_do_catch.call_deferred()


func _do_catch() -> void:
	_catching = false
	catches += 1
	alarm_active = false
	player.teleport(_checkpoint_pos)
	_rig.snap_to_target()
	for guard in map.guards:
		guard.reset_to_patrol()
	_flash.modulate.a = 1.0
	create_tween().tween_property(_flash, "modulate:a", 0.0, catch_fade_time)
	_update_status()


## Stops the world and shows the whole overlay. Aim mode (step 4) replaces this.
func set_overlay_view(on: bool) -> void:
	overlay_view = on
	player.set_physics_process(not on)
	for guard in map.guards:
		guard.set_physics_process(not on)
	for node in get_tree().get_nodes_in_group(&"stealth_noise"):
		node.set_physics_process(not on)
	_redraw_guards()
	_update_status()


func _redraw_guards() -> void:
	for guard in map.guards:
		guard.redraw()


func _physics_process(delta: float) -> void:
	if _done or overlay_view:
		return
	player.move_yaw = _rig.yaw()
	if alarm_active:
		_unseen += delta
		if _unseen >= alarm_lose_time:
			alarm_active = false
			for guard in map.guards:
				guard.start_search(last_seen_pos)
	var pos := player.global_position
	player.set_concealed(map.is_concealed(pos))
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
	for guard in map.guards:
		guard.set_physics_process(false)
	_update_status()
	finished.emit(_result())


func _result() -> Dictionary:
	return {
		"outcome": "clean" if alarms == 0 else "loud",
		"alarms": alarms,
		"catches": catches,
	}


func _update_status() -> void:
	_hint.text = HINT % OverlayMode.keys()[overlay_mode].to_lower()
	if _done:
		_status.text = "EXIT REACHED   %s" % [_result()]
		return
	var parts := PackedStringArray()
	if crisis_level > 0:
		parts.append("CRISIS %d" % crisis_level)
	if alarm_active:
		parts.append("ALARM")
	if overlay_view:
		parts.append("OVERLAY VIEW (world stopped)")
	_status.text = "   ".join(parts)
