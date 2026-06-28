extends Node2D

@export var luigi_scene: PackedScene
@export var luigi_spawn_offset := Vector2(20, 0)

@onready var mario: Mario = $Mario


func _ready() -> void:
	var players := 1
	if has_node("/root/GameConfig"):
		players = get_node("/root/GameConfig").players
	if players >= 2:
		_spawn_luigi()


func _spawn_luigi() -> void:
	if luigi_scene == null or mario == null:
		return
	var luigi := luigi_scene.instantiate() as Mario
	add_child(luigi)
	luigi.name = "Luigi"
	luigi.global_position = mario.global_position + luigi_spawn_offset
