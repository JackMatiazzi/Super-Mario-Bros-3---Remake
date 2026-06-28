class_name Estrela extends CharacterBody2D

const SPEED_X = 80.0
const BOUNCE_SPEED = -320.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction := 1.0
var coletado := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	velocity.y = BOUNCE_SPEED
	sprite.play("default")


func ser_coletado(mario: Mario) -> void:
	if coletado:
		return
	coletado = true
	mario.pickup_item("estrela")
	queue_free()


func _physics_process(delta: float) -> void:
	if coletado:
		return
	velocity.y += gravity * delta
	velocity.x = direction * SPEED_X
	move_and_slide()

	if is_on_floor():
		velocity.y = BOUNCE_SPEED

	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if abs(collision.get_normal().x) > 0.5:
			direction = sign(collision.get_normal().x)
