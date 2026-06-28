class_name VenusFireball extends Area2D

const SPEED = 95.0
const LIFE_TIME = 5.0

var direction := Vector2.LEFT
var life_time := LIFE_TIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2) -> void:
	direction = new_direction


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Mario:
		body.take_damage()
		queue_free()
