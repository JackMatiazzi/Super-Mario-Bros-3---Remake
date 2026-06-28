class_name Cogumelo1UP extends CharacterBody2D

const SPEED = 45.0

var direction := 1.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coletado := false


func ser_coletado(mario: Mario) -> void:
	if coletado:
		return
	coletado = true
	mario.pickup_item("1up")
	queue_free()


func _physics_process(delta: float) -> void:
	if coletado:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = direction * SPEED
	move_and_slide()

	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if abs(collision.get_normal().x) > 0.5:
			direction = sign(collision.get_normal().x)
