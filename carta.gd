extends Node2D

# ID da carta: configure no Inspetor de cada uma como 0, 1 ou 2
@export var id_carta: int = 0

# AJUSTADO: Agora tipados corretamente como TileMapLayer
@onready var img_cogumelo: TileMapLayer = $Cogumelo
@onready var img_estrela: TileMapLayer = $Estrela
@onready var img_flor: TileMapLayer = $Flor

# Controle para não quebrar o efeito de piscar
var esta_piscando: bool = false

func _ready() -> void:
	atualizar_visual()

func _process(_delta: float) -> void:
	# Só atualiza o visual fixo se NÃO estiver rodando a animação de piscar
	if not esta_piscando:
		atualizar_visual()

func atualizar_visual() -> void:
	img_cogumelo.hide()
	img_estrela.hide()
	img_flor.hide()
	
	# Descobre qual item deve exibir olhando o inventário do jogador ativo no Global
	var item_atual = Global.TipoItem.NENHUM
	if Global.jogador_ativo == Global.Jogador.MARIO:
		item_atual = Global.cartas_mario[id_carta]
	else:
		item_atual = Global.cartas_luigi[id_carta]
	
	# Mostra o TileMapLayer correto
	match item_atual:
		Global.TipoItem.COGUMELO: img_cogumelo.show()
		Global.TipoItem.ESTRELA: img_estrela.show()
		Global.TipoItem.FLOR: img_flor.show()
		Global.TipoItem.NENHUM: pass

# FUNÇÃO AJUSTADA PARA O TILEMAPLAYER PISCAR
func iniciar_pisca_item(tipo_recebido: Global.TipoItem) -> void:
	esta_piscando = true
	
	# Esconde tudo antes de começar
	img_cogumelo.hide()
	img_estrela.hide()
	img_flor.hide()
	
	var sprite_alvo: TileMapLayer = null
	match tipo_recebido:
		Global.TipoItem.COGUMELO: sprite_alvo = img_cogumelo
		Global.TipoItem.ESTRELA: sprite_alvo = img_estrela
		Global.TipoItem.FLOR: sprite_alvo = img_flor
		
	if sprite_alvo:
		# Faz o grupo de blocos do TileMapLayer ligar e desligar 8 vezes
		for i in range(8):
			sprite_alvo.visible = !sprite_alvo.visible
			await get_tree().create_timer(0.15).timeout
			
	esta_piscando = false
	atualizar_visual() # Restaura o estado visual definitivo baseado no Global
