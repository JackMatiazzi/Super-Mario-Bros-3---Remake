class_name Goomba extends CharacterBody2D

const WALK_SPEED = 28.0
const HOP_VELOCITY = -210.0
const DEFEAT_TIME = 0.45
const MICRO_SPAWN_TIME = 3.0

@export var winged := false
@export var spawns_micro := false
@export var red_winged := false
@export var enemy_tint := Color.WHITE
@export var micro_scene: PackedScene
@export var direction := -1.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var hop_time := 0.7
var spawn_time := MICRO_SPAWN_TIME
var defeated_time := 0.0
var contact_time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var interaction_area: Area2D = $InteractionArea
@onready var wings: Node2D = $Wings


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	wings.visible = winged
	sprite.modulate = enemy_tint


func _physics_process(delta: float) -> void:
	contact_time = max(contact_time - delta, 0.0)
	if defeated_time > 0.0:
		defeated_time -= delta
		if defeated_time <= 0.0:
			queue_free()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	elif winged:
		hop_time -= delta
		if hop_time <= 0.0:
			velocity.y = HOP_VELOCITY
			hop_time = 0.9

	if winged and spawns_micro and micro_scene:
		spawn_time -= delta
		if spawn_time <= 0.0:
			spawn_time = MICRO_SPAWN_TIME
			call_deferred("_spawn_micro")

	velocity.x = direction * WALK_SPEED
	move_and_slide()
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Mario:
			_handle_mario_contact(collider)
		elif abs(collision.get_normal().x) > 0.5:
			direction = sign(collision.get_normal().x)
	sprite.flip_h = direction > 0.0
	_update_animation()


func _update_animation() -> void:
	sprite.play("walk")


func _on_body_entered(body: Node2D) -> void:
	if body is Mario:
		_handle_mario_contact(body)


func _handle_mario_contact(mario: Mario) -> void:
	if contact_time > 0.0 or defeated_time > 0.0:
		return
	var stomped := mario.global_position.y < global_position.y - 4.0 and mario.velocity.y >= 0.0
	if stomped:
		contact_time = 0.2
		mario.bounce_from_enemy()
		mario.adicionar_pontos(100)
		if winged:
			winged = false
			wings.hide()
			velocity.y = 0.0
		else:
			_defeat()
	else:
		contact_time = 0.3
		mario.take_damage()


func _defeat() -> void:
	defeated_time = DEFEAT_TIME
	velocity = Vector2.ZERO
	body_collision.set_deferred("disabled", true)
	interaction_area.set_deferred("monitoring", false)
	sprite.play("squashed")


func _spawn_micro() -> void:
	var micro = micro_scene.instantiate()
	get_parent().add_child(micro)
	micro.global_position = global_position + Vector2(0, -12)


func hit_by_tail(_source_position: Vector2) -> void:
	if defeated_time <= 0.0:
		_defeat()


func hit_by_shell(_source_position: Vector2) -> void:
	if defeated_time <= 0.0:
		_defeat()
