class_name ExitZone
extends Area2D
## Leaving the chamber. Goes to next_scene, or shows an end message if none is set yet.

@export_file("*.tscn") var next_scene: String = ""
@export var end_message: String = "End of prototype"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b10
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	if next_scene != "":
		GameManager.go_to_chamber(next_scene)
		return
	(body as Player).controls_enabled = false
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_message"):
		hud.call("show_message", end_message)
