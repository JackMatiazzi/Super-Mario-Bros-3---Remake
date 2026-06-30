class_name TitleMenu extends Control

@export_file("*.tscn") var next_scene := "res://scenes/levels/mundo_1.tscn"

@onready var screen: Control = $Screen
@onready var selector: Node2D = $Screen/Selector
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _blink_time := 0.0

var _iniciando_jogo := false

func _ready() -> void:
	_update_selector()
	Global.resetar_jogo_total()
	if not audio_player.playing:
		audio_player.play()

func _process(delta: float) -> void:
	if _iniciando_jogo:
		_blink_time += delta
		
		selector.visible = int(_blink_time * 8.0) % 2 == 0 
	else:
		selector.visible = true

func _input(event: InputEvent) -> void:
	# Se o jogo já estiver fazendo a transição, ignora qualquer botão apertado
	if _iniciando_jogo:
		return
		
	if _is_select_input(event):
		Global.quantidade_jogadores = 2 if Global.quantidade_jogadores == 1 else 1
		_blink_time = 0.0
		_update_selector()
		# Toca o clipe de movimento
		_tocar_audio("Move")
		accept_event()
		
	elif _is_confirm_input(event):
		# Trava os controles e inicia a transição
		_iniciando_jogo = true
		# Toca o clipe de confirmação
		_tocar_audio("Confirm")
		_start_game()
		accept_event()

func _update_selector() -> void:
	selector.position = Vector2(-58.0, 40.0 if Global.quantidade_jogadores == 1 else 56.5)

func _start_game() -> void:
	print("Numero de jogadores selecionado = ",Global.quantidade_jogadores)
		
	await get_tree().create_timer(1.0).timeout 
	
	get_tree().change_scene_to_file(next_scene)

func _is_select_input(event: InputEvent) -> bool:
	if event.is_action_pressed("up") or event.is_action_pressed("down") or event.is_action_pressed("left") or event.is_action_pressed("right"):
		return true
	return false

func _is_confirm_input(event: InputEvent) -> bool:
	if event.is_action_pressed("enter"):
		return true
	return false

# ==========================================
# FUNÇÃO AUXILIAR PARA O ÁUDIO INTERATIVO
# ==========================================
func _tocar_audio(nome_clip: String) -> void:
	# Captura o controlador de reprodução interno (Playback)
	var playback = audio_player.get_stream_playback()
	
	# Troca para o clipe desejado pelo nome (certifique-se de que os nomes batem com os do editor)
	if playback:
		playback.switch_to_clip_by_name(nome_clip)
