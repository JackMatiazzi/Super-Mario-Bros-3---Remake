extends CharacterBody2D
class_name Cogumelo1UP

@export var cena_pontuacao: PackedScene 
@export var VELOCIDADE: float = 60.0
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direcao: float = 1.0 # 1 para direita, -1 para esquerda
var movimento_ativo: bool = false

func _ready() -> void:
	# Começa sem colidir com o jogador para não ser pego enquanto está dentro do bloco
	set_collision_layer_value(1, false) 

func iniciar_movimento() -> void:
	movimento_ativo = true
	# Reativa a colisão com o jogador agora que ele saiu do bloco
	set_collision_layer_value(1, true)
	
	# Descobre onde o jogador está para nascer correndo para o lado oposto (estilo clássico)
	var jogadores = get_tree().get_nodes_in_group("jogador")
	if jogadores.size() > 0:
		var jogador = jogadores[0]
		if jogador.global_position.x > global_position.x:
			direcao = -1.0
		else:
			direcao = 1.0

func _physics_process(delta: float) -> void:
	if not movimento_ativo:
		return

	# Aplica gravidade
	if not is_on_floor():
		velocity.y += gravidade * delta

	# Movimento horizontal fixo
	velocity.x = direcao * VELOCIDADE

	move_and_slide()

	# Se bater em uma parede na horizontal, ele inverte a direção
	if is_on_wall():
		direcao *= -1.0

# Esta função é chamada pelo detector_itens do jogador quando ele encosta no cogumelo
func ser_coletado(jogador: JogadorSMB3) -> void:
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	jogador._item_audio("cogumelo")
	Global.adicionar_vida(nome_jogador, 1)
	
	Global.adicionar_pontuacao(nome_jogador, 1000)
	_criar_popup_pontos(1000, global_position + Vector2(0, -16))
	
	queue_free() # Remove o cogumelo da fase

func _criar_popup_pontos(valor: int, posicao: Vector2) -> void:
	if cena_pontuacao:
		var pontos = cena_pontuacao.instantiate()
		if pontos.has_node("Label"):
			pontos.get_node("Label").text = str(valor)
		pontos.global_position = posicao
		get_parent().add_child(pontos)


#class_name Cogumelo1UP extends CharacterBody2D
#
#const SPEED = 45.0
#
#var direction := 1.0
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#var coletado := false
#
#
#func ser_coletado(mario: Mario) -> void:
	#if coletado:
		#return
	#coletado = true
	#mario.pickup_item("1up")
	#queue_free()
#
#
#func _physics_process(delta: float) -> void:
	#if coletado:
		#return
	#if not is_on_floor():
		#velocity.y += gravity * delta
	#velocity.x = direction * SPEED
	#move_and_slide()
#
	#for index in range(get_slide_collision_count()):
		#var collision := get_slide_collision(index)
		#if abs(collision.get_normal().x) > 0.5:
			#direction = sign(collision.get_normal().x)
