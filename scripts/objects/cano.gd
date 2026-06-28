class_name Cano extends StaticBody2D

@export_category("Transporte")
@export var permite_entrada := false
@export var permite_saida := false
@export var destino_global: Vector2 = Vector2.ZERO
@export var acao_entrada := "down"
@export var acao_saida := "up"

@export_category("Spawn")
@export var spawn_habilitado := false
@export var spawn_scene: PackedScene
@export var spawn_interval := 2.8
@export var spawn_direction := -1.0
@export var spawn_offset := Vector2(0, -24)
@export var max_spawn_vivos := 3

@onready var area_topo: Area2D = $AreaTopo

var _mario: Mario = null
var _spawn_time := 0.0
var _spawned: Array[Node] = []

func _ready() -> void:
	area_topo.body_entered.connect(_on_body_entered)
	area_topo.body_exited.connect(_on_body_exited)
	_spawn_time = spawn_interval
	set_process(_has_transport() or spawn_habilitado)

func _on_body_entered(body: Node2D) -> void:
	if body is Mario:
		_mario = body

func _on_body_exited(body: Node2D) -> void:
	if body is Mario:
		_mario = null

func _process(delta: float) -> void:
	_process_transport()
	_process_spawn(delta)


func _process_transport() -> void:
	if _mario == null or not _mario.is_on_floor() or not _has_transport():
		return
	var enter_action := _mario.down_action if _mario != null else acao_entrada
	var exit_action := _mario.up_action if _mario != null else acao_saida
	if permite_entrada and (Input.is_action_just_pressed(acao_entrada) or Input.is_action_just_pressed(enter_action)):
		_transport_mario()
	elif permite_saida and (Input.is_action_just_pressed(acao_saida) or Input.is_action_just_pressed(exit_action)):
		_transport_mario()


func _transport_mario() -> void:
	if destino_global != Vector2.ZERO:
		_mario.global_position = destino_global
		_mario.velocity = Vector2.ZERO
	_mario = null


func _process_spawn(delta: float) -> void:
	if not spawn_habilitado or spawn_scene == null:
		return
	_cleanup_spawned()
	if _spawned.size() >= max_spawn_vivos:
		return
	_spawn_time -= delta
	if _spawn_time <= 0.0:
		_spawn_time = spawn_interval
		_spawn_from_pipe()


func _spawn_from_pipe() -> void:
	var instance := spawn_scene.instantiate()
	get_parent().add_child(instance)
	instance.global_position = global_position + spawn_offset
	if instance.get("direction") != null:
		instance.set("direction", spawn_direction)
	_spawned.append(instance)


func _cleanup_spawned() -> void:
	_spawned = _spawned.filter(func(node: Node) -> bool:
		return is_instance_valid(node)
	)


func _has_transport() -> bool:
	return destino_global != Vector2.ZERO and (permite_entrada or permite_saida)
