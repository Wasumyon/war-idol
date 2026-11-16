class_name LitZone
extends Area2D
## A pool of fixed light (a working ceiling lamp). Standing here exposes the
## player to any guard whose vision cone reaches him, even with his lamp off.
## The light itself is a separate PointLight2D in the scene.

var _players: Array[Node2D] = []


func _ready() -> void:
	add_to_group("lit_zone")
	collision_layer = 0
	collision_mask = 0b10  # player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not _players.has(body):
		_players.append(body)


func _on_body_exited(body: Node2D) -> void:
	_players.erase(body)


func contains_player(p: Node2D) -> bool:
	return _players.has(p)
