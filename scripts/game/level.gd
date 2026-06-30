extends Node2D

@onready var mensagem_final = $"Informaçoes/ControlMensagem"
@onready var carta_mensagem = $"Informaçoes/ControlMensagem/HBoxContainer/Carta"
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var jogador = $Jogador

var level_tempo: int = 300
var fase_ativa: bool = true
var tempo_acumulado: float = 0.0

func _ready() -> void:
	# Reseta o tempo no Global logo que a fase começa
	Global.iniciar_tempo_da_fase(level_tempo)
	
	if not audio_player.playing:
		audio_player.play()
	_tocar_audio("Fase 1")

func _process(delta: float) -> void:
	# Só diminui o tempo se a fase ainda não acabou e o tempo for maior que zero
	if not fase_ativa or Global.tempo_restante <= 0:
		return
		
	# Acumula as frações de segundo (delta)
	tempo_acumulado += delta
	
	# Quando der 1 segundo completo, diminui o tempo no Global e zera o acumulador
	if tempo_acumulado >= 1.0:
		Global.tempo_restante -= 1
		tempo_acumulado -= 1.0
		
		if Global.tempo_restante == 0:
			print("Tempo esgotado! Mario/Luigi perde uma vida.")
			jogador._acionar_morte()

# ==========================================
# LÓGICA DE FIM DE FASE (CHAMADA PELA CARTA)
# ==========================================
func concluir_fase(item_coletado: Global.TipoItem) -> void:
	fase_ativa = false # Trava o cronômetro
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	
	print("COURSE CLEAR! Item pego: ", item_coletado)
	_tocar_audio("Level Clear")
	
	# 1. Adiciona a carta no inventário (a sua interface das cartas vai ler isso automaticamente!)
	var slot_usado: int = Global.adicionar_carta(item_coletado)
	
	if slot_usado != -1:
		carta_mensagem.id_carta = slot_usado
	mensagem_final.show()
	
	# 2. Converte o tempo restante em pontuação progressivamente com um Tween
	if Global.tempo_restante > 0:
		var total_segundos_sobrando: int = Global.tempo_restante
	
		var velocidade_contagem: float = 1.5 / float(total_segundos_sobrando)
	
		var t = create_tween()
	
		# Criamos uma sequência exata: para cada 1 segundo que sobrou no relógio...
		for i in range(total_segundos_sobrando):
			# 1. Executa a troca: tira 1 do tempo e coloca 50 nos pontos
			t.tween_callback(func():
				Global.tempo_restante -= 1
				Global.adicionar_pontuacao(nome_jogador, 1)
			# DICA RETRÔ: Se tiver um som curto de ponto/moeda, ative aqui
			# _tocar_audio("Tick")
			)
			# 2. Espera o micro-tempo antes de ir para o próximo segundo
			t.tween_interval(velocidade_contagem)
	
	await get_tree().create_timer(4.0).timeout
	
	if has_node("/root/Transicao"):
		Transicao.fechar_tela_retangulo("res://scenes/levels/mundo_1.tscn")
		print("Voltando para o mapa!")

# ==========================================
# FUNÇÃO AUXILIAR PARA O ÁUDIO INTERATIVO
# ==========================================
func _tocar_audio(nome_clip: String) -> void:
	# Captura o controlador de reprodução interno (Playback)
	var playback = audio_player.get_stream_playback()
	
	# Troca para o clipe desejado pelo nome (certifique-se de que os nomes batem com os do editor)
	if playback:
		playback.switch_to_clip_by_name(nome_clip)
