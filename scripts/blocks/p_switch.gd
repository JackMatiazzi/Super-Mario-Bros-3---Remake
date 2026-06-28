class_name PSwitch extends StaticBody2D

signal p_chave_ativada

@onready var area_golpe: Area2D = $AreaGolpe
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var ativado := false


func _ready() -> void:
	area_golpe.body_entered.connect(_on_golpe)
	sprite.play("normal")


func _on_golpe(body: Node2D) -> void:
	if body is Mario and not ativado:
		_ativar()


func _ativar() -> void:
	ativado = true
	sprite.play("pressionado")
	p_chave_ativada.emit()
	_sacudir()


func _sacudir() -> void:
	var pos_original = position
	var tween = create_tween()
	tween.tween_property(self, "position", pos_original + Vector2(0, -4), 0.05)
	tween.tween_property(self, "position", pos_original, 0.05)
