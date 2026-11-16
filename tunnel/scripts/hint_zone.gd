class_name HintZone
extends Area2D
## Shows a control hint on the HUD while the player stands inside.
## If hide_when_torch_on, the hint disappears once the lamp is lit (tutorial prompts).

@export_multiline var text: String = ""
@export var enabled: bool = false
@export var hide_when_torch_on: bool = false
@export var only_when_torch_on: bool = false

var _player: Player


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b10 if enabled else 0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var visible_now: bool = true
	if hide_when_torch_on and _player.is_torch_on:
		visible_now = false
	if only_when_torch_on and not _player.is_torch_on:
		visible_now = false
	_set_hint(text if visible_now else "")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body as Player


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_set_hint("")


func _set_hint(value: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_hint"):
		hud.call("set_hint", value)
