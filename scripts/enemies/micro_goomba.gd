class_name MicroGoomba extends CharacterBody2D

const SPEED = 45.0
const HOP_VELOCITY = -150.0
const JUMPS_TO_REMOVE = 3

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var target: Mario
var attached := false
var attached_slot := 0
var jump_count := 0

@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	target = get_tree().get_first_node_in_group("player") as Mario


func _physics_process(delta: float) -> void:
	if attached:
		_update_attached()
		return
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Mario
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = HOP_VELOCITY
	velocity.x = sign(target.global_position.x - global_position.x) * SPEED
	move_and_slide()


func _on_body_entered(body: Node2D) -> void:
	if body is Mario and not attached:
		attached = true
		target = body
		attached_slot = target.attach_micro_goomba()
		if attached_slot < 0:
			queue_free()
			return
		velocity = Vector2.ZERO
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		interaction_area.set_deferred("monitoring", false)


func _update_attached() -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var offsets := [
		Vector2(-7, 2),
		Vector2(7, 2),
		Vector2(0, -7),
	]
	global_position = target.global_position + offsets[attached_slot % offsets.size()]
	if Input.is_action_just_pressed(target.jump_action):
		jump_count += 1
		if jump_count >= JUMPS_TO_REMOVE:
			target.detach_micro_goomba()
			queue_free()


func hit_by_shell(_source_position: Vector2) -> void:
	if attached and is_instance_valid(target):
		target.detach_micro_goomba()
	queue_free()


func hit_by_tail(_source_position: Vector2) -> void:
	hit_by_shell(_source_position)
