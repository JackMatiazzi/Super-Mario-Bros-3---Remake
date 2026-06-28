class_name Mario extends CharacterBody2D

const WALK_SPEED = 90.0
const RUN_SPEED = 150.0
const JUMP_VELOCITY = -380.0
const FRICTION = 150.0
const SKID_FRICTION = 600.0
const FLIGHT_CHARGE_TIME = 1.2
const FLIGHT_DURATION = 4.0
const FLIGHT_FLAP_VELOCITY = -210.0
const GLIDE_MAX_FALL_SPEED = 75.0
const TAIL_ATTACK_DURATION = 0.32
const HURT_INVINCIBILITY_TIME = 1.0
const DEATH_DURATION = 2.0
const DEATH_FREEZE_TIME = 0.35
const BLOCK_BREAK_COOLDOWN = 0.15
const MAX_MICRO_GOOMBAS = 3
const GROW_TRANSFORM_TIME = 0.72
const GROW_FLASH_STEP = 0.08
const ADULT_COLLISION_SIZE = Vector2(16, 27)
const ADULT_COLLISION_POSITION = Vector2(0, 2.5)
const CROUCH_COLLISION_SIZE = Vector2(16, 16)
const CROUCH_COLLISION_POSITION = Vector2(0, 8)
const SCORE_POPUP_SCENE = preload("res://scenes/ui/score_popup.tscn")

enum MarioState { PEQUENO, ADULTO, RACCOON }

@export var character_name := "Mario"
@export var player_group := "player_1"
@export var sprite_tint := Color.WHITE
@export var left_action := "left"
@export var right_action := "right"
@export var up_action := "up"
@export var down_action := "down"
@export var jump_action := "jump"
@export var run_action := "run"
@export var camera_enabled := true

var state: MarioState = MarioState.PEQUENO
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var flight_charge := 0.0
var flight_time := 0.0
var tail_attack_time := 0.0
var pontos := 0
var moedas := 0
var hurt_time := 0.0
var dying := false
var death_time := 0.0
var death_freeze_time := 0.0
var block_break_time := 0.0
var micro_goombas := 0
var transforming := false
var transform_time := 0.0
var transform_flash_time := 0.0
var transform_show_adult := false
var crouching := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_pequeno: CollisionShape2D = $CollisionShapePequeno
@onready var collision_adulto: CollisionShape2D = $CollisionShapeAdulto
@onready var tail_hitbox: Area2D = $TailHitbox
@onready var area_pickup: Area2D = $AreaPickup


func _ready() -> void:
	add_to_group("player")
	add_to_group(player_group)
	sprite.modulate = sprite_tint
	if has_node("Camera2D"):
		$Camera2D.enabled = camera_enabled
	tail_hitbox.body_entered.connect(_on_tail_target_entered)
	tail_hitbox.area_entered.connect(_on_tail_target_entered)
	area_pickup.body_entered.connect(_on_item_entered)


func _on_item_entered(body: Node2D) -> void:
	if body.has_method("ser_coletado"):
		body.ser_coletado(self)
	elif body.has_method("try_pickup"):
		body.try_pickup(self)


func _physics_process(delta: float) -> void:
	if dying:
		_process_death(delta)
		return
	if transforming:
		_process_grow_transform(delta)
		return
	for body in area_pickup.get_overlapping_bodies():
		_on_item_entered(body)
	_update_power_timers(delta)
	_apply_gravity(delta)
	_update_crouch_state()
	_handle_jump()
	_handle_movement(delta)
	_handle_tail_attack()
	_handle_animation()
	move_and_slide()
	queue_redraw()


func _draw() -> void:
	if state != MarioState.RACCOON or flight_charge <= 0.0:
		return
	var progress := flight_charge / FLIGHT_CHARGE_TIME
	draw_rect(Rect2(-9, -24, 18, 3), Color("281000"), true)
	draw_rect(Rect2(-8, -23, 16 * progress, 1), Color("f8d800"), true)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		if state == MarioState.RACCOON and Input.is_action_pressed(jump_action) and velocity.y > GLIDE_MAX_FALL_SPEED:
			velocity.y = GLIDE_MAX_FALL_SPEED


func _handle_jump() -> void:
	if not Input.is_action_just_pressed(jump_action):
		return
	if crouching:
		return
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		if state == MarioState.RACCOON and flight_charge >= FLIGHT_CHARGE_TIME:
			flight_time = FLIGHT_DURATION
	elif state == MarioState.RACCOON and flight_time > 0.0:
		velocity.y = FLIGHT_FLAP_VELOCITY


func _handle_movement(delta: float) -> void:
	var direction := Input.get_axis(left_action, right_action)
	if crouching:
		velocity.x = move_toward(velocity.x, 0, SKID_FRICTION * delta)
		flight_charge = 0.0
		return

	var speed = RUN_SPEED if Input.is_action_pressed(run_action) else WALK_SPEED
	speed *= max(0.55, 1.0 - micro_goombas * 0.15)

	if direction != 0:
		var going_opposite = (direction > 0 and velocity.x < 0) or (direction < 0 and velocity.x > 0)
		if going_opposite:
			velocity.x = move_toward(velocity.x, 0, SKID_FRICTION * delta)
		else:
			velocity.x = direction * speed
		sprite.flip_h = direction > 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	if state == MarioState.RACCOON and is_on_floor() and direction != 0 and Input.is_action_pressed(run_action) and abs(velocity.x) >= RUN_SPEED * 0.95:
		flight_charge = min(flight_charge + delta, FLIGHT_CHARGE_TIME)
	elif is_on_floor():
		flight_charge = max(flight_charge - delta * 2.0, 0.0)


func _handle_tail_attack() -> void:
	if state == MarioState.RACCOON and Input.is_action_just_pressed(run_action) and not crouching:
		tail_attack_time = TAIL_ATTACK_DURATION
	tail_hitbox.position.x = 13.0 if sprite.flip_h else -13.0
	tail_hitbox.monitoring = tail_attack_time > 0.0
	if tail_attack_time > 0.0:
		_process_tail_overlaps()


func _update_power_timers(delta: float) -> void:
	flight_time = max(flight_time - delta, 0.0)
	tail_attack_time = max(tail_attack_time - delta, 0.0)
	hurt_time = max(hurt_time - delta, 0.0)
	block_break_time = max(block_break_time - delta, 0.0)
	var alpha := 0.45 if hurt_time > 0.0 and int(hurt_time * 12.0) % 2 == 0 else 1.0
	sprite.modulate = Color(sprite_tint.r, sprite_tint.g, sprite_tint.b, alpha)


func _on_tail_target_entered(target: Node) -> void:
	if tail_attack_time <= 0.0:
		return
	_apply_tail_hit(target)


func _process_tail_overlaps() -> void:
	for body in tail_hitbox.get_overlapping_bodies():
		_apply_tail_hit(body)
	for area in tail_hitbox.get_overlapping_areas():
		_apply_tail_hit(area)


func _apply_tail_hit(target: Node) -> void:
	if target == self or target == tail_hitbox or is_ancestor_of(target):
		return
	if target is Mario:
		return
	if target.has_method("hit_by_tail"):
		target.hit_by_tail(global_position)
	elif target.has_method("take_damage"):
		target.take_damage()


func _get_state_prefix() -> String:
	match state:
		MarioState.ADULTO: return "adulto_"
		MarioState.RACCOON: return "raccoon_"
	return "pequeno_"


func _update_crouch_state() -> void:
	var should_crouch := state != MarioState.PEQUENO and is_on_floor() and Input.is_action_pressed(down_action)
	if crouching == should_crouch:
		return
	crouching = should_crouch
	_update_collision()


func _handle_animation() -> void:
	var prefix = _get_state_prefix()
	var direction := Input.get_axis(left_action, right_action)
	if crouching:
		var crouch_animation: String = prefix + "crouch"
		sprite.play(crouch_animation if sprite.sprite_frames.has_animation(crouch_animation) else prefix + "idle")
	elif state == MarioState.RACCOON and tail_attack_time > 0.0:
		sprite.play("raccoon_tail")
	elif state == MarioState.RACCOON and flight_time > 0.0 and not is_on_floor():
		sprite.play("raccoon_fly")
	elif not is_on_floor():
		sprite.play(prefix + "jump")
	elif direction != 0:
		sprite.play(prefix + "walk")
	else:
		sprite.play(prefix + "idle")


func _update_collision() -> void:
	collision_pequeno.set_deferred("disabled", state != MarioState.PEQUENO)
	collision_adulto.set_deferred("disabled", state == MarioState.PEQUENO)
	var adult_shape := collision_adulto.shape as RectangleShape2D
	if adult_shape:
		adult_shape.size = CROUCH_COLLISION_SIZE if crouching else ADULT_COLLISION_SIZE
	collision_adulto.position = CROUCH_COLLISION_POSITION if crouching else ADULT_COLLISION_POSITION


func pickup_item(tipo: String) -> void:
	match tipo:
		"cogumelo":
			if state == MarioState.PEQUENO:
				_start_grow_transform()
		"folha_super":
			state = MarioState.RACCOON
			crouching = false
			flight_charge = 0.0
			_update_collision()
		"1up":
			_add_powerup_score(1000)
		"estrela":
			_add_powerup_score(1000)


func adicionar_pontos(valor: int) -> void:
	pontos += valor


func coletar_moeda(valor_pontos := 100) -> void:
	moedas += 1
	adicionar_pontos(valor_pontos)


func _add_powerup_score(valor: int) -> void:
	adicionar_pontos(valor)
	var popup := SCORE_POPUP_SCENE.instantiate()
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector2(0, -28)
	popup.value = valor


func _start_grow_transform() -> void:
	transforming = true
	transform_time = GROW_TRANSFORM_TIME
	transform_flash_time = 0.0
	transform_show_adult = false
	velocity = Vector2.ZERO
	sprite.play("pequeno_idle")
	_add_powerup_score(1000)


func _process_grow_transform(delta: float) -> void:
	transform_time -= delta
	transform_flash_time -= delta
	if transform_flash_time <= 0.0:
		transform_flash_time = GROW_FLASH_STEP
		transform_show_adult = not transform_show_adult
		if transform_show_adult:
			sprite.play("adulto_idle")
			collision_pequeno.set_deferred("disabled", true)
			collision_adulto.set_deferred("disabled", false)
		else:
			sprite.play("pequeno_idle")
			collision_pequeno.set_deferred("disabled", false)
			collision_adulto.set_deferred("disabled", true)
	if transform_time <= 0.0:
		transforming = false
		state = MarioState.ADULTO
		crouching = false
		_update_collision()
		sprite.play("adulto_idle")


func bounce_from_enemy() -> void:
	velocity.y = -260.0


func get_facing_direction() -> float:
	return 1.0 if sprite.flip_h else -1.0


func try_break_block() -> bool:
	if block_break_time > 0.0:
		return false
	block_break_time = BLOCK_BREAK_COOLDOWN
	return true


func attach_micro_goomba() -> int:
	if micro_goombas >= MAX_MICRO_GOOMBAS:
		return -1
	var slot := micro_goombas
	micro_goombas += 1
	return slot


func detach_micro_goomba() -> void:
	micro_goombas = max(micro_goombas - 1, 0)


func take_damage() -> void:
	if dying or hurt_time > 0.0:
		return
	match state:
		MarioState.ADULTO:
			state = MarioState.PEQUENO
			crouching = false
			hurt_time = HURT_INVINCIBILITY_TIME
			_update_collision()
		MarioState.RACCOON:
			state = MarioState.ADULTO
			crouching = false
			hurt_time = HURT_INVINCIBILITY_TIME
			flight_charge = 0.0
			flight_time = 0.0
			_update_collision()
		MarioState.PEQUENO:
			_die()


func _die() -> void:
	dying = true
	death_time = DEATH_DURATION
	death_freeze_time = DEATH_FREEZE_TIME
	velocity = Vector2.ZERO
	collision_pequeno.set_deferred("disabled", true)
	collision_adulto.set_deferred("disabled", true)
	tail_hitbox.set_deferred("monitoring", false)
	sprite.flip_h = false
	sprite.position.y = 0.0
	sprite.rotation = 0.0
	sprite.play("pequeno_die")


func _process_death(delta: float) -> void:
	if death_freeze_time > 0.0:
		death_freeze_time -= delta
		if death_freeze_time <= 0.0:
			velocity.y = -260.0
		return
	death_time -= delta
	velocity.y += gravity * delta
	global_position += velocity * delta
	if death_time <= 0.0:
		death_time = INF
		get_tree().reload_current_scene()
