class_name IntroVideo extends Control

@export_file("*.tscn") var next_scene := "res://scenes/ui/title_menu.tscn"

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer


func _ready() -> void:
	video_player.finished.connect(_go_to_title_menu)
	video_player.play()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("space") or event is InputEventMouseButton and event.pressed:
		_go_to_title_menu()
		accept_event()


func _go_to_title_menu() -> void:
	get_tree().change_scene_to_file(next_scene)
