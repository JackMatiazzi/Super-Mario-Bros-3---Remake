class_name TijoloFragmento extends Node2D

@export var velocity := Vector2.ZERO
@export var gravity := 720.0
@export var spin_speed := 18.0
@export var lifetime := 0.55

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	velocity.y += gravity * delta
	position += velocity * delta
	rotation += spin_speed * delta
	if _time >= lifetime:
		queue_free()
