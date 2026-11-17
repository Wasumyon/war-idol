class_name CheckpointZone
extends Area2D
## Walking through saves this zone's position as the respawn point for the chamber.

@export var respawn_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b10
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var pos: Vector2 = Vector2(global_position.x, body.global_position.y) + respawn_offset
		TunnelManager.i.set_checkpoint(pos)
