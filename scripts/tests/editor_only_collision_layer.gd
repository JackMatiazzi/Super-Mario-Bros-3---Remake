@tool
extends TileMapLayer

@export_range(0.0, 1.0, 0.01) var editor_alpha := 0.28


func _ready() -> void:
	_update_visibility()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE or what == NOTIFICATION_POSTINITIALIZE:
		_update_visibility()


func _update_visibility() -> void:
	if Engine.is_editor_hint():
		modulate = Color(0.0, 0.7, 1.0, editor_alpha)
	else:
		modulate = Color(0.0, 0.7, 1.0, 0.0)
