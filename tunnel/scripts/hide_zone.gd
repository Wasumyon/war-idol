class_name HideZone
extends Area2D
## A spot he can flatten against (pillar, alcove). Standing here and pressing
## action_hide (W / Up) puts him in the hidden state. Used from Chamber 2 on.


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b10  # player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).enter_hide_zone()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).exit_hide_zone()
