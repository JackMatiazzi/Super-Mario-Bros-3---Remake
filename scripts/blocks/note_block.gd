class_name NoteBlock extends StaticBody2D

const IMPULSO = -520.0

@onready var area_topo: Area2D = $AreaTopo


func _ready() -> void:
	area_topo.body_entered.connect(_on_mario_pousou)


func _on_mario_pousou(body: Node2D) -> void:
	if body is Mario and body.velocity.y > 0:
		body.velocity.y = IMPULSO
		_sacudir()


func _sacudir() -> void:
	var pos_original = position
	var tween = create_tween()
	tween.tween_property(self, "position", pos_original + Vector2(0, -4), 0.05)
	tween.tween_property(self, "position", pos_original, 0.05)
