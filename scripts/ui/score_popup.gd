class_name ScorePopup extends Node2D

@export var value := 1000
@export var lifetime := 0.65
@export var rise_speed := 22.0

@onready var label: Label = $Label

var _time := 0.0


func _ready() -> void:
	label.text = "+%d" % value


func _process(delta: float) -> void:
	_time += delta
	position.y -= rise_speed * delta
	modulate.a = max(1.0 - (_time / lifetime), 0.0)
	if _time >= lifetime:
		queue_free()
