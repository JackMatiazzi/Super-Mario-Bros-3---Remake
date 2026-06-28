extends Node2D

@onready var itens: Node2D = $"Levels/Informaçoes/Control/Info/Itens"
@onready var mensagem: CanvasLayer = $Mensagens

# Referências para os dois personagens
@onready var mario: AnimatedSprite2D = $Mario
@onready var anim_mario: AnimationPlayer = $AnimMario
@onready var luigi: AnimatedSprite2D = $Luigi
@onready var anim_luigi: AnimationPlayer = $AnimLuigi

# Ponto de partida no Inspetor
@export var ponto_inicial: MapPoint

# Variáveis de controle de posição
var mario_ponto_atual: MapPoint
var luigi_ponto_atual: MapPoint

# Controle global de movimento, turnos e janelas
var esta_se_movendo: bool = false
var exibindo_mensagem: bool = false # O NOSSO CADEADO DE INPUT
var velocidad_tween: float = 0.3

func _ready() -> void:
	if ponto_inicial:
		# Ambos começam no mesmo ponto físico
		mario_ponto_atual = ponto_inicial
		mario.global_position = mario_ponto_atual.global_position
		
		# Configuração inicial do Mario
		mario.play("mario") 
		mario.z_index = 1
		
		# COMPORTAMENTO COM 1 OU 2 JOGADORES
		if Global.quantidade_jogadores == 2:
			luigi_ponto_atual = ponto_inicial
			luigi.global_position = luigi_ponto_atual.global_position
			luigi.play("icon")
			anim_luigi.stop()
			luigi.z_index = 0
			luigi.show() # Garante que ele aparece se for 2P
		else:
			luigi.hide() # Esconde o Luigi se for jogo de 1 jogador
		
		# DISPARA A MENSAGEM INICIAL DO MARIO BUSCANDO AS VIDAS DO GLOBAL
		executar_mensagem("mario", Global.vidas_mario)
		
	else:
		push_error("Por favor, atribua o Ponto Inicial no Inspetor do mapa!")

func _process(_delta: float) -> void:
	# Ignora TOTALMENTE os comandos se estiver se movendo OU se a mensagem estiver na tela
	if esta_se_movendo or exibindo_mensagem:
		return
		
	# ==========================================
	# CONTROLES DE AÇÃO
	# ==========================================
	
	# Trocar de jogador (Espaço) - SÓ ATIVA SE FOR JOGO DE 2 JOGADORES
	if Input.is_action_just_pressed("space") and Global.quantidade_jogadores == 2:
		alternar_jogador()
		return
		
	# Entrar no Level (Enter)
	if Input.is_action_just_pressed("enter"):
		entrar_no_level()
		return
		
	# Alternar Painel de Info (Ctrl)
	if Input.is_action_just_pressed("ctrl"):
		alternar_painel_info()
		return
		
	# ==========================================
	# CONTROLES DE MOVIMENTO
	# ==========================================
	
	if Input.is_action_just_pressed("ui_right"):
		tentar_mover("direita")
	elif Input.is_action_just_pressed("ui_left"):
		tentar_mover("esquerda")
	elif Input.is_action_just_pressed("ui_up"):
		tentar_mover("acima")
	elif Input.is_action_just_pressed("ui_down"):
		tentar_mover("abaixo")

# FUNÇÃO DA SEQUÊNCIA AUTOMÁTICA DA MENSAGEM
func executar_mensagem(nome_jogador: String, vidas: int) -> void:
	exibindo_mensagem = true # Tranca os controles do mapa
	
	mensagem.mostrar_mensagem(nome_jogador, vidas) # Abre o painel
	
	await get_tree().create_timer(2.5).timeout 
	
	mensagem.ocultar_mensagem() # Esconde o painel
	
	exibindo_mensagem = false # Destranca os controles do mapa

func alternar_jogador() -> void:
	# Dupla segurança: se por acaso tentar alternar em 1 jogador, bloqueia
	if Global.quantidade_jogadores == 1:
		return
		
	if Global.jogador_ativo == Global.Jogador.MARIO:
		Global.jogador_ativo = Global.Jogador.LUIGI
		
		mario.play("icon")
		anim_mario.stop()
		luigi.play("luigi")
		anim_luigi.play()
		luigi.z_index = 1
		mario.z_index = 0
		
		print("Agora jogando com: LUIGI")
		# Lendo as vidas do Luigi direto do Global
		executar_mensagem("luigi", Global.vidas_luigi)
	else:
		Global.jogador_ativo = Global.Jogador.MARIO
		
		luigi.play("icon")
		anim_luigi.stop()
		mario.play("mario") 
		anim_mario.play()
		mario.z_index = 1
		luigi.z_index = 0
		
		print("Agora jogando com: MARIO")
		# Lendo as vidas do Mario direto do Global
		executar_mensagem("mario", Global.vidas_mario)

func entrar_no_level() -> void:
	var ponto_atual_do_ativo: MapPoint = mario_ponto_atual if Global.jogador_ativo == Global.Jogador.MARIO else luigi_ponto_atual
	if ponto_atual_do_ativo.level:
		print("ENTER pressionado: Iniciando transição para a fase!")
		get_tree().change_scene_to_file("res://level_1.tscn")
	else:
		print("ENTER pressionado: Não tem nenhuma fase neste ponto.")

func alternar_painel_info() -> void:
	print("CTRL pressionado: Abrindo/Fechando painel de informações!")
	if itens.visible:
		itens.hide()
	else:
		itens.show()
	
func tentar_mover(direcao: String) -> void:
	var ponto_atual_do_ativo: MapPoint = mario_ponto_atual if Global.jogador_ativo == Global.Jogador.MARIO else luigi_ponto_atual
	var propriedade_status: String = direcao + "_liberado"
	
	if ponto_atual_do_ativo.get(propriedade_status) == false:
		print("Caminho bloqueado!")
		return

	var caminho_node_path: NodePath = ponto_atual_do_ativo.get(direcao)
	
	if caminho_node_path and not caminho_node_path.is_empty():
		var proximo_ponto = ponto_atual_do_ativo.get_node(caminho_node_path) as MapPoint
		if proximo_ponto:
			mover_jogador_ativo(proximo_ponto)

func mover_jogador_ativo(novo_ponto: MapPoint) -> void:
	esta_se_movendo = true
	var node_para_mover: AnimatedSprite2D = mario if Global.jogador_ativo == Global.Jogador.MARIO else luigi
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(node_para_mover, "global_position", novo_ponto.global_position, velocidad_tween)
	tween.finished.connect(_ao_chegar_no_ponto.bind(novo_ponto))

func _ao_chegar_no_ponto(novo_ponto: MapPoint) -> void:
	if Global.jogador_ativo == Global.Jogador.MARIO:
		mario_ponto_atual = novo_ponto
	else:
		luigi_ponto_atual = novo_ponto
		
	esta_se_movendo = false
