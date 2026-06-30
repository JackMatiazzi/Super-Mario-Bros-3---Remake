extends CharacterBody2D
class_name FolhaRaccoon

@export var cena_pontuacao: PackedScene

var movimento_ativo: bool = false
var tempo_decorrido: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	set_collision_layer_value(1, false)

func iniciar_movimento() -> void:
	movimento_ativo = true
	set_collision_layer_value(1, true)
	
	# Dá um impulso inicial para cima saindo do bloco antes de começar a flutuar
	velocity.y = -180.0

func _physics_process(delta: float) -> void:
	if not movimento_ativo:
		return

	tempo_decorrido += delta

	# Se ela ainda estiver subindo pelo impulso inicial, apenas aplica uma gravidade leve
	if velocity.y < 0:
		velocity.y += 400.0 * delta
	else:
		# Lógica clássica de flutuar: velocidade de queda bem lenta e suave
		velocity.y = 35.0
		
		# Efeito Zigue-Zague usando a função matemática Seno (sin)
		# O valor 120.0 controla a largura do balanço, e 4.0 controla a velocidade do balanço
		velocity.x = sin(tempo_decorrido * 4.0) * 80.0
		
		# Muda o flip do sprite dependendo de para onde ela está flutuando no zigue-zague
		if velocity.x > 5:
			sprite.flip_h = false
		elif velocity.x < -5:
			sprite.flip_h = true

	move_and_slide()

func ser_coletado(jogador: JogadorSMB3) -> void:
	jogador._item_audio("folha_raccoon")
	# Transforma o jogador diretamente em Raccoon (independente se era pequeno ou super)
	if jogador.estado_atual != JogadorSMB3.EstadoPoder.RACCOON:
		jogador.estado_atual = JogadorSMB3.EstadoPoder.RACCOON
		jogador._atualizar_visual_personagem()
		jogador._ajustar_caixa_colisao()
	
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	Global.adicionar_pontuacao(nome_jogador, 1000)
	_criar_popup_pontos(1000, global_position + Vector2(0, -16))
	
	queue_free()

func _criar_popup_pontos(valor: int, posicao: Vector2) -> void:
	if cena_pontuacao:
		var pontos = cena_pontuacao.instantiate()
		if pontos.has_node("Label"):
			pontos.get_node("Label").text = str(valor)
		pontos.global_position = posicao
		get_parent().add_child(pontos)

#class_name FolhaSuper extends Area2D
#
#var tempo := 0.0
#var origem_y := 0.0
#
#@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
#
#
#func _ready() -> void:
	#origem_y = position.y
	#body_entered.connect(_on_body_entered)
	#sprite.play("default")
#
#
#func _process(delta: float) -> void:
	#tempo += delta
	#position.y = origem_y + sin(tempo * 3.0) * 3.0
	#rotation = sin(tempo * 2.0) * 0.12
#
#
#func _on_body_entered(body: Node2D) -> void:
	#if body is Mario:
		#body.pickup_item("folha_super")
		#queue_free()
