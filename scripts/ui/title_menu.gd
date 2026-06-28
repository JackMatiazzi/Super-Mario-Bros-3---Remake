class_name TitleMenu extends Control

@export_file("*.tscn") var next_scene := "res://scenes/levels/world_1_1.tscn"

@onready var screen: Control = $Screen
@onready var selector: Node2D = $Screen/Selector

var selected_players := 1
var _blink_time := 0.0


func _ready() -> void:
	_update_selector()


func _process(delta: float) -> void:
	_blink_time += delta
	selector.visible = int(_blink_time * 5.0) % 2 == 0


func _input(event: InputEvent) -> void:
	if _is_select_input(event):
		selected_players = 2 if selected_players == 1 else 1
		_blink_time = 0.0
		_update_selector()
		accept_event()
	elif _is_confirm_input(event):
		_start_game()
		accept_event()
	elif event is InputEventMouseMotion:
		_update_selection_from_mouse(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _update_selection_from_mouse(event.position):
			_start_game()
			accept_event()


func _update_selector() -> void:
	selector.position = Vector2(215.0, 461.0 if selected_players == 1 else 514.0)


func _start_game() -> void:
	if has_node("/root/GameConfig"):
		get_node("/root/GameConfig").players = selected_players
	get_tree().change_scene_to_file(next_scene)


func _is_select_input(event: InputEvent) -> bool:
	if event.is_action_pressed("up") or event.is_action_pressed("down") or event.is_action_pressed("left") or event.is_action_pressed("right"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.physical_keycode == KEY_UP or event.physical_keycode == KEY_DOWN or event.physical_keycode == KEY_LEFT or event.physical_keycode == KEY_RIGHT
	return false


func _is_confirm_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_KP_ENTER
	return false


func _update_selection_from_mouse(mouse_position: Vector2) -> bool:
	var local_position := screen.get_global_transform().affine_inverse() * mouse_position
	if local_position.x < 220.0 or local_position.x > 560.0:
		return false
	if local_position.y >= 430.0 and local_position.y <= 472.0:
		selected_players = 1
	elif local_position.y >= 482.0 and local_position.y <= 526.0:
		selected_players = 2
	else:
		return false
	_blink_time = 0.0
	_update_selector()
	return true
