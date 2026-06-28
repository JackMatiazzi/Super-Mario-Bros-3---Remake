class_name Koopa extends CharacterBody2D

const WALK_SPEED = 35.0
const SHELL_SPEED = 180.0
const PICKUP_OFFSET = Vector2(14, 0)
const SHELL_REVIVE_TIME = 6.0
const SHELL_WARNING_TIME = 1.5

@export var red_variant := false
@export var winged := false
@export var direction := -1.0

enum State { WALKING, SHELL_IDLE, SHELL_MOVING, CARRIED }

var state := State.WALKING
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var carrier: Mario
var ignore_mario_time := 0.0
var shell_timer := 0.0
var wing_hop_time := 0.7

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var interaction_area: Area2D = $InteractionArea
@onready var floor_ray: RayCast2D = $FloorRay


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	if red_variant:
		sprite.modulate = Color(1.0, 0.38, 0.38, 1.0)


func _physics_process(delta: float) -> void:
	ignore_mario_time = max(ignore_mario_time - delta, 0.0)
	if state == State.CARRIED:
		_update_carried()
		return
	if state == State.SHELL_IDLE:
		_update_shell_timer(delta)

	if not is_on_floor():
		velocity.y += gravity * delta
	elif winged and state == State.WALKING:
		wing_hop_time -= delta
		if wing_hop_time <= 0.0:
			velocity.y = -210.0
			wing_hop_time = 0.9
	velocity.x = _current_speed() * direction
	move_and_slide()
	_handle_slide_collisions()
	_update_ledge_detection()
	_update_animation()


func _current_speed() -> float:
	match state:
		State.WALKING: return WALK_SPEED
		State.SHELL_MOVING: return SHELL_SPEED
	return 0.0


func _handle_slide_collisions() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Mario and ignore_mario_time <= 0.0:
			_handle_mario_contact(collider)
		elif state == State.SHELL_MOVING and collider != self and collider.has_method("hit_by_shell"):
			collider.hit_by_shell(global_position)
			if abs(collision.get_normal().x) > 0.2:
				direction = sign(collision.get_normal().x)
		elif abs(collision.get_normal().x) > 0.5:
			direction = sign(collision.get_normal().x)


func _on_body_entered(body: Node2D) -> void:
	if body is Mario and ignore_mario_time <= 0.0:
		_handle_mario_contact(body)


func _handle_mario_contact(mario: Mario) -> void:
	var stomped := mario.global_position.y < global_position.y - 5.0 and mario.velocity.y >= 0.0
	if stomped:
		mario.bounce_from_enemy()
		if state == State.WALKING:
			mario.adicionar_pontos(100)
			if winged:
				winged = false
				velocity.y = 0.0
			else:
				_enter_shell()
		elif state == State.SHELL_MOVING:
			_stop_shell()
		return

	if state == State.SHELL_IDLE:
		if Input.is_action_pressed(mario.run_action):
			_pick_up(mario)
		else:
			_kick(sign(global_position.x - mario.global_position.x))
	elif state == State.WALKING or state == State.SHELL_MOVING:
		mario.take_damage()


func _enter_shell() -> void:
	state = State.SHELL_IDLE
	shell_timer = SHELL_REVIVE_TIME
	velocity = Vector2.ZERO
	var shell_shape := RectangleShape2D.new()
	shell_shape.size = Vector2(14, 14)
	body_collision.set_deferred("shape", shell_shape)
	body_collision.set_deferred("position", Vector2(0, 7))
	sprite.position.y = 7.0
	sprite.play("shell_idle")


func _stop_shell() -> void:
	state = State.SHELL_IDLE
	shell_timer = SHELL_REVIVE_TIME
	velocity.x = 0.0
	sprite.play("shell_idle")


func _kick(new_direction: float) -> void:
	state = State.SHELL_MOVING
	shell_timer = 0.0
	direction = new_direction if new_direction != 0.0 else 1.0
	ignore_mario_time = 0.25
	sprite.play("shell_spin")


func _update_shell_timer(delta: float) -> void:
	shell_timer -= delta
	if shell_timer <= 0.0:
		_leave_shell()
	elif shell_timer <= SHELL_WARNING_TIME:
		sprite.play("shell_spin")


func _leave_shell() -> void:
	state = State.WALKING
	var walk_shape := RectangleShape2D.new()
	walk_shape.size = Vector2(14, 28)
	body_collision.set_deferred("shape", walk_shape)
	body_collision.set_deferred("position", Vector2.ZERO)
	sprite.position.y = 0.0
	sprite.play("walk")
	ignore_mario_time = 0.5


func _pick_up(mario: Mario) -> void:
	if state != State.SHELL_IDLE:
		return
	state = State.CARRIED
	carrier = mario
	velocity = Vector2.ZERO
	sprite.position.y = 7.0
	sprite.play("shell_idle")
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	interaction_area.set_deferred("monitoring", false)


func _update_carried() -> void:
	if not is_instance_valid(carrier):
		queue_free()
		return
	var facing := carrier.get_facing_direction()
	global_position = carrier.global_position + Vector2(PICKUP_OFFSET.x * facing, PICKUP_OFFSET.y)
	if not Input.is_action_pressed(carrier.run_action):
		carrier = null
		set_deferred("collision_layer", 2)
		set_deferred("collision_mask", 3)
		interaction_area.set_deferred("monitoring", true)
		_kick(facing)


func try_pickup(mario: Mario) -> void:
	if state == State.SHELL_IDLE and Input.is_action_pressed(mario.run_action):
		_pick_up(mario)


func ser_coletado(mario: Mario) -> void:
	try_pickup(mario)


func _update_animation() -> void:
	if state == State.WALKING:
		sprite.position.y = 0.0
		sprite.flip_h = direction > 0.0
		sprite.play("winged_walk" if winged else "walk")
	elif state == State.SHELL_MOVING:
		sprite.play("shell_spin")
	elif state == State.SHELL_IDLE and shell_timer > SHELL_WARNING_TIME:
		sprite.play("shell_idle")


func _update_ledge_detection() -> void:
	if not red_variant or state != State.WALKING or not is_on_floor():
		return
	floor_ray.position.x = direction * 8.0
	if not floor_ray.is_colliding():
		direction *= -1.0


func hit_by_tail(source_position: Vector2) -> void:
	if state == State.WALKING:
		_enter_shell()
	elif state == State.SHELL_IDLE:
		_kick(sign(global_position.x - source_position.x))
	elif state == State.SHELL_MOVING:
		direction *= -1.0


func hit_by_shell(source_position: Vector2) -> void:
	if state == State.CARRIED:
		return
	if winged:
		winged = false
		velocity = Vector2(sign(global_position.x - source_position.x) * 80.0, -180.0)
		return
	queue_free()
