class_name FolhaSuper extends Area2D

var tempo := 0.0
var origem_y := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	origem_y = position.y
	body_entered.connect(_on_body_entered)
	sprite.play("default")


func _process(delta: float) -> void:
	tempo += delta
	position.y = origem_y + sin(tempo * 3.0) * 3.0
	rotation = sin(tempo * 2.0) * 0.12


func _on_body_entered(body: Node2D) -> void:
	if body is Mario:
		body.pickup_item("folha_super")
		queue_free()
