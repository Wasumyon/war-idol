extends Node3D
class_name BattlePocket
## A battle on one side of the road: two opposing fighters, at a random spacing,
## trading fire until one is destroyed. Some advance; some hold.

@export var min_spread := 12.0
@export var max_spread := 34.0
@export var fighter_hp := 5
@export var approach_chance := 0.5

var rng: RandomNumberGenerator


func _ready() -> void:
	add_to_group("pocket")
	var spread := rng.randf_range(min_spread, max_spread) if rng != null else randf_range(min_spread, max_spread)

	var a := Fighter.new()
	a.rng = rng
	a.team = 0
	a.team_color = Color(0.3, 0.85, 1.0)
	a.hp = fighter_hp
	var a_roll := rng.randf() if rng != null else randf()
	a.behavior = Fighter.Behavior.APPROACH if a_roll < approach_chance else Fighter.Behavior.HOLD
	add_child(a)
	a.position = Vector3(-spread * 0.5, 2.0, 0)

	var b := Fighter.new()
	b.rng = rng
	b.team = 1
	b.team_color = Color(1.0, 0.5, 0.2)
	b.hp = fighter_hp
	var b_roll := rng.randf() if rng != null else randf()
	b.behavior = Fighter.Behavior.APPROACH if b_roll < approach_chance else Fighter.Behavior.HOLD
	add_child(b)
	b.position = Vector3(spread * 0.5, 2.0, 0)

	a.target = b
	b.target = a
