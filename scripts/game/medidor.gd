extends HBoxContainer

# As texturas que você já configurou no Inspetor
@export var textura_seta_vazia: Texture2D
@export var textura_seta_cheia: Texture2D
@export var textura_p_vazio: Texture2D
@export var textura_p_cheio: Texture2D

# Pega todos os 7 TextureRects filhos automaticamente
@onready var icones: Array[Node] = get_children()

# Variáveis para controlar o efeito de piscar do "P"
var piscando_p: bool = false
var p_ligado: bool = false
var timer_piscar: SceneTreeTimer = null

# Guarda o nível atual para sabermos quando a velocidade mudou
var nivel_atual: int = 0

func _ready() -> void:
	# Começa o jogo com tudo zerado e limpo
	atualizar_medidor(0)

# ESTA É A FUNÇÃO PRINCIPAL QUE O SCRIPT DO INFO VAI CHAMAR
func atualizar_medidor(nivel: int) -> void:
	# Garante que o nível fique estritamente entre 0 e 7
	nivel = clamp(nivel, 0, 7)
	nivel_atual = nivel
	
	# Se não estiver no nível máximo (7), desliga o efeito de piscar imediatamente
	if nivel < 7:
		piscando_p = false
	
	# Percorre as 6 primeiras setas (índices de 0 a 5)
	for i in range(6):
		var seta = icones[i] as TextureRect
		if seta:
			# Se o índice for menor que o nível, a seta acende
			seta.texture = textura_seta_cheia if i < nivel else textura_seta_vazia
	
	# Lógica do 7º ícone: O botão "P" (índice 6)
	var icone_p = icones[6] as TextureRect
	if icone_p:
		if nivel == 7:
			# Se acabou de atingir o nível máximo e não estava piscando, inicia o efeito
			if not piscando_p:
				piscando_p = true
				_loop_piscar_p()
		else:
			# Se não for nível 7, o P fica totalmente apagado
			icone_p.texture = textura_p_vazio

# FUNÇÃO INTERNA QUE FAZ O "P" PISCAR EM LOOP
func _loop_piscar_p() -> void:
	var icone_p = icones[6] as TextureRect
	
	# Enquanto o jogador mantiver a corrida no máximo (nível 7)
	while piscando_p and nivel_atual == 7:
		# Inverte o estado visual (se estava ligado desliga, se estava desligado liga)
		p_ligado = not p_ligado
		
		if icone_p:
			icone_p.texture = textura_p_cheio if p_ligado else textura_p_vazio
			
			# [OPCIONAL] Se o seu colega de áudio colocar o som de sirene, 
			# você pode tocar o efeito sonoro bem aqui toda vez que o 'p_ligado' for true!
		
		# Cria uma pausa de 0.15 segundos antes de mudar o estado do piscar novamente
		await get_tree().create_timer(0.15).timeout
