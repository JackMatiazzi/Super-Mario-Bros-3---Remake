class_name BlocoTijolo extends StaticBody2D

const FRAGMENTO_CENA := preload("res://scenes/blocks/tijolo_fragmento.tscn")

@onready var area_golpe: Area2D = $AreaGolpe

var quebrado := false

func _ready() -> void:
	area_golpe.body_entered.connect(_on_golpe)

func _on_golpe(body: Node2D) -> void:
	if quebrado or not body is Mario:
		return
	hit_from_below(body)


func hit_from_below(mario: Mario) -> void:
	if quebrado:
		return
	if mario.state == Mario.MarioState.PEQUENO:
		_sacudir()
	elif mario.try_break_block():
		_quebrar()


func hit_by_tail(_source_position: Vector2) -> void:
	if quebrado:
		return
	_quebrar()


func hit_by_shell(_source_position: Vector2) -> void:
	if quebrado:
		return
	_quebrar()

func _sacudir() -> void:
	var pos_original = position
	var tween = create_tween()
	tween.tween_property(self, "position", pos_original + Vector2(0, -4), 0.05)
	tween.tween_property(self, "position", pos_original, 0.05)

func _quebrar() -> void:
	quebrado = true
	_spawn_fragments()
	queue_free()


func _spawn_fragments() -> void:
	for data in [
		[Vector2(-4, -4), Vector2(-92, -250), -20.0],
		[Vector2(4, -4), Vector2(92, -250), 20.0],
		[Vector2(-4, 4), Vector2(-72, -170), -16.0],
		[Vector2(4, 4), Vector2(72, -170), 16.0],
	]:
		var fragment := FRAGMENTO_CENA.instantiate()
		fragment.global_position = global_position + data[0]
		fragment.velocity = data[1]
		fragment.spin_speed = data[2]
		get_tree().current_scene.add_child(fragment)
