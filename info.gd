extends Node2D

# Referências dos componentes internos
@onready var label_vida: Label = $Control/Vida
@onready var label_pontos: Label = $Jogador/Pontos
@onready var label_moedas: Label = $Jogador/MoedasIcon/Moedas
@onready var jogador_icon: AnimatedSprite2D = $Control/JogadorIcon
@onready var medidor_p: HBoxContainer = $Jogador/Medidor
@onready var info_item: TileMapLayer = $Itens


func _process(_delta: float) -> void:
	# Fica atualizando as informações a cada frame do jogo
	atualizar_dados()

func atualizar_dados() -> void:
	# 1. VERIFICA QUEM É O JOGADOR ATIVO E ATUALIZA OS TEXTOS
	if Global.jogador_ativo == Global.Jogador.MARIO:
		# Se o Mario estiver jogando, mostra os dados dele
		label_vida.text = "%d" % Global.vidas_mario
		label_moedas.text = "%d" % Global.moedas_mario
		
		# Formata a pontuação para ter sempre 7 dígitos (ex: 0000000) igual ao Mario 3
		label_pontos.text = "%07d" % Global.pontuacao_mario
		
		# Muda o ícone do HUD para o Mario
		if not info_item.visible:
			if jogador_icon.animation != "mario":
				jogador_icon.play("mario")
		else:
			if jogador_icon.animation != "mario_item":
				jogador_icon.play("mario_item")
			
	else:
		# Se for o Luigi, mostra os dados dele
		label_vida.text = "%d" % Global.vidas_luigi
		label_moedas.text = "%d" % Global.moedas_luigi
		label_pontos.text = "%07d" % Global.pontuacao_luigi
		
		# Muda o ícone do HUD para o Luigi
		if not info_item.visible:
			if jogador_icon.animation != "luigi":
				jogador_icon.play("luigi")
		else:
			if jogador_icon.animation != "luigi_item":
				jogador_icon.play("luigi_item")

# Quando o script do Player quiser atualizar a barra, ele chama essa função aqui!
func atualizar_velocidade(nivel_velocidade: int) -> void:
	if medidor_p:
		medidor_p.atualizar_medidor(nivel_velocidade)
