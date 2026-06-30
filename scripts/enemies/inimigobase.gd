extends CharacterBody2D
class_name InimigoBase

@export_category("Configurações Base")
@export var velocidade: float = 40.0
@export var dano_pontos: int = 100

@export var cena_pontuacao: PackedScene 

var direcao: int = -1 # -1 = Esquerda, 1 = Direita
var direcao_inicial: int = -1
var gravidade: float = 980.0
var morto: bool = false
var ativo: bool = false 

# Sistema de Memória de Posição
var posicao_inicial: Vector2

# Nós filhos necessários na cena
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var detector_combate: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colisao_fisica: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Armazena o estado de nascimento do inimigo
	posicao_inicial = global_position
	direcao_inicial = direcao
	
	# Conexão segura de sinais via código
	if notifier:
		notifier.screen_entered.connect(_on_screen_entered)
		notifier.screen_exited.connect(_on_screen_exited)
	if detector_combate:
		detector_combate.body_entered.connect(_on_corpo_entrou)

func _physics_process(delta: float) -> void:
	if morto: return

	# Se não estiver na tela, congela a física e força o posicionamento no spawn
	if not ativo:
		global_position = posicao_inicial
		velocity = Vector2.ZERO
		return

	# Aplica gravidade se estiver no ar
	if not is_on_floor():
		velocity.y += gravidade * delta
		
	_comportamento_movimento(delta)
	move_and_slide()
	
	# Bateu na parede, inverte o lado
	if is_on_wall():
		direcao *= -1

# Padrão de movimento lateral (Sobrescrito nos filhos se necessário)
func _comportamento_movimento(_delta: float) -> void:
	velocity.x = direcao * velocidade
	if sprite and sprite.sprite_frames.has_animation("andando"):
		sprite.play("andando")

# ==============================================================================
# LÓGICA DE COMBATE (PISADA VS DANO NO MARIO)
# ==============================================================================
func _on_corpo_entrou(body: Node2D) -> void:
	if morto: return
	
	var jogador = body as JogadorSMB3
	if jogador:
		if jogador.nocauteado: return
		
		# Verifica se o pé do jogador está acima do meio do inimigo e caindo
		if jogador.velocity.y > 0 and jogador.global_position.y < global_position.y:
			if Input.is_action_pressed("jump"):
				jogador.velocity.y = -360.0 # Impulso alto
			else:
				jogador.velocity.y = -200.0 # Impulso baixo
				
			ser_esmagado(jogador)
		else:
			# Qualquer outro ângulo de colisão machuca o Mario/Luigi
			jogador.tomar_dano()

func ser_esmagado(jogador: JogadorSMB3) -> void:
	morto = true
	ativo = false 
	velocity = Vector2.ZERO
	jogador._item_audio("goomba")
	_alternar_colisoes(false) # Desliga as colisões instantaneamente
	
	# Adiciona a pontuação dinamicamente para o jogador correto
	var nome_jog = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	Global.adicionar_pontuacao(nome_jog, dano_pontos)

# ==============================================================================
# CONTROLE DE VISÃO DA CÂMERA (MATRIZ CANVAS)
# ==============================================================================
func _on_screen_entered() -> void:
	if not morto:
		ativo = true
		_alternar_colisoes(true)

func _on_screen_exited() -> void:
	if morto: return
	if not ativo: return
	
	# Desliga as colisões no limbo fora da tela para evitar atritos indesejados
	_alternar_colisoes(false)
	velocity = Vector2.ZERO
	
	# Projeta a posição global de spawn direto para coordenadas de pixels da tela
	var posicao_spawn_na_tela: Vector2 = get_canvas_transform() * posicao_inicial
	
	# Cria a caixa de pixels da resolução real visível
	var limites_da_tela = Rect2(Vector2.ZERO, get_viewport_rect().size)
	
	# Se a posição inicial do inimigo não estiver mais contida nos pixels da tela, reseta
	if not limites_da_tela.has_point(posicao_spawn_na_tela):
		_resetar_inimigo()

func _resetar_inimigo() -> void:
	ativo = false
	global_position = posicao_inicial
	direcao = direcao_inicial
	velocity = Vector2.ZERO
	
	# Devolve a colisão ao corpo agora que ele retornou para casa em segurança
	_alternar_colisoes(true)
	
	# Se for um paragoomba, regenera as asas dele ao resetar
	if has_method("restaurar_estado"):
		call("restaurar_estado")

# ==============================================================================
# FUNÇÃO AUXILIAR DE SEGURANÇA FÍSICA
# ==============================================================================
func _alternar_colisoes(habilitado: bool) -> void:
	# set_deferred evita travamentos e erros de sincronia no motor de física
	if colisao_fisica:
		colisao_fisica.set_deferred("disabled", !habilitado)
	if detector_combate:
		detector_combate.set_deferred("monitoring", habilitado)

func _criar_popup_pontos(valor: int, posicao: Vector2) -> void:
	if cena_pontuacao:
		var pontos = cena_pontuacao.instantiate()
		if pontos.has_node("Label"):
			pontos.get_node("Label").text = str(valor)
		pontos.global_position = posicao
		get_parent().add_child(pontos)
