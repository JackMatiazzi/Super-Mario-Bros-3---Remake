class_name VenusFireTrap extends Area2D

const CYCLE_TIME = 4.0
const MOVE_TIME = 0.55
const HIDDEN_OFFSET = 28.0
const SAFE_DISTANCE = 28.0

@export var projectile_scene: PackedScene
@export var shoots_fire := true

var cycle_time := 0.0
var visible_y := 0.0
var fired := false
var active := false
var target: Mario

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	visible_y = global_position.y
	global_position.y = visible_y + HIDDEN_OFFSET
	body_entered.connect(_on_body_entered)
	target = get_tree().get_first_node_in_group("player") as Mario
	_set_active(false)


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Mario
		return
	if cycle_time <= 0.0 and abs(target.global_position.x - global_position.x) < SAFE_DISTANCE:
		global_position.y = visible_y + HIDDEN_OFFSET
		return

	cycle_time = fmod(cycle_time + delta, CYCLE_TIME)
	if cycle_time < MOVE_TIME:
		global_position.y = lerp(visible_y + HIDDEN_OFFSET, visible_y, cycle_time / MOVE_TIME)
		_set_active(true)
		fired = false
	elif cycle_time < 2.1:
		global_position.y = visible_y
		_set_active(true)
		if shoots_fire and cycle_time > 1.0 and not fired:
			fired = true
			call_deferred("_shoot")
	elif cycle_time < 2.1 + MOVE_TIME:
		global_position.y = lerp(visible_y, visible_y + HIDDEN_OFFSET, (cycle_time - 2.1) / MOVE_TIME)
		_set_active(true)
	else:
		global_position.y = visible_y + HIDDEN_OFFSET
		_set_active(false)

	if is_instance_valid(target):
		sprite.flip_h = target.global_position.x > global_position.x


func _set_active(value: bool) -> void:
	if active == value:
		return
	active = value
	set_deferred("monitoring", value)


func _shoot() -> void:
	if not projectile_scene or not is_instance_valid(target):
		return
	var side := -1.0
	if target.global_position.x > global_position.x:
		side = 1.0
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(side * 6.0, -16.0)
	projectile.setup(Vector2(side, -0.35).normalized())


func _on_body_entered(body: Node2D) -> void:
	if active and body is Mario:
		body.take_damage()


func hit_by_tail(_source_position: Vector2) -> void:
	queue_free()


func hit_by_shell(_source_position: Vector2) -> void:
	queue_free()
