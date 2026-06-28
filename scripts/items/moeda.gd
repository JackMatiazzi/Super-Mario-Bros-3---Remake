class_name Moeda extends Area2D

var coletada := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Mario and not coletada:
		coletada = true
		set_deferred("monitoring", false)
		body.coletar_moeda(100)
		queue_free()
