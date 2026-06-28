class_name BlocoItem extends StaticBody2D

enum ItemConteudo { NENHUM, COGUMELO, FOLHA, CUSTOM }

const COGUMELO_SCENE = preload("res://scenes/items/cogumelo.tscn")
const FOLHA_SCENE = preload("res://scenes/items/folha_super.tscn")

@export var conteudo: ItemConteudo = ItemConteudo.COGUMELO
@export var item_cena: PackedScene

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = $AreaGolpe

var usado: bool = false

func _ready() -> void:
	area_golpe.body_entered.connect(_on_golpe)
	sprite.play("cheio")

func _on_golpe(body: Node2D) -> void:
	if not body is Mario or usado:
		return
	hit_from_below(body)

func _ativar() -> void:
	usado = true
	sprite.play("vazio")
	_sacudir()
	if _get_item_scene() != null:
		call_deferred("_criar_item")


func hit_from_below(_mario: Mario) -> void:
	if not usado:
		_ativar()


func hit_by_tail(_source_position: Vector2) -> void:
	if not usado:
		_ativar()


func hit_by_shell(_source_position: Vector2) -> void:
	if not usado:
		_ativar()


func _criar_item() -> void:
	var scene = _get_item_scene()
	if scene == null:
		return
	var item = scene.instantiate()
	get_parent().add_child(item)
	item.global_position = global_position + Vector2(0, -16)


func _get_item_scene():
	match conteudo:
		ItemConteudo.NENHUM:
			return null
		ItemConteudo.COGUMELO:
			return COGUMELO_SCENE
		ItemConteudo.FOLHA:
			return FOLHA_SCENE
		ItemConteudo.CUSTOM:
			return item_cena
	return null

func _sacudir() -> void:
	var pos_original = position
	var tween = create_tween()
	tween.tween_property(self, "position", pos_original + Vector2(0, -4), 0.05)
	tween.tween_property(self, "position", pos_original, 0.05)
