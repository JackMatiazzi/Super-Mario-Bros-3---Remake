extends StaticBody2D
class_name BlocoTijolo

enum TipoConteudo { VAZIO, MOEDA, COGUMELO, COGUMELO_VIDA, FOLHA_RACCOON }

@export var conteudo: TipoConteudo = TipoConteudo.VAZIO
@export var quantidade_moedas: int = 1

@export_category("Cenas dos Itens")
@export var cena_moeda_pulo: PackedScene   # A cena daquela moedinha que pula e some
@export var cena_cogumelo: PackedScene     # Tua cena do Super Cogumelo
@export var cena_cogumelo_vida: PackedScene     # Tua cena do Cogumelo verde
@export var cena_folha: PackedScene        # Tua cena da Folha Raccoon
@export var cena_pontuacao: PackedScene    # Tua cena de texto (100, 200, etc)

@export_category("Mecânica de Quebrar")
@export var cena_pedaco_bloco: PackedScene # Arraste aqui a sua cena de pedacinho de tijolo (Node2D)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colisao: CollisionShape2D = $CollisionShape2D

var ja_foi_atingido: bool = false
var posicao_original: Vector2

func _ready() -> void:
	posicao_original = global_position
	sprite.play("cheio") # O sprite padrão do tijolo piscando/estático

func bater_bloco(eh_pequeno: bool) -> void:
	if ja_foi_atingido:
		return
	
	# REGRA DO SMB3: Se o bloco estiver VAZIO e o Mario for GRANDE, o bloco quebra!
	if conteudo == TipoConteudo.VAZIO and not eh_pequeno:
		_quebrar_bloco()
		return
	
	# Se o Mario for pequeno ou o bloco tiver item, ele apenas faz o "pulo"
	_executar_pulo_bloco()
	
	# Só libera item se de fato NÃO for vazio
	if conteudo != TipoConteudo.VAZIO:
		# Não marca como "já atingido" de vez aqui se for moeda múltipla, a lógica da moeda cuida disso
		await get_tree().create_timer(0.2).timeout
		_liberar_item_da_cena()
	else:
		# Se era vazio e o Mario bateu sendo pequeno, ele apenas vira bloco inativo e não quebra
		ja_foi_atingido = true

func _executar_pulo_bloco() -> void:
	# Se o conteúdo for vazio ou for a última moeda, avisa que o bloco vai "desativar"
	if conteudo == TipoConteudo.VAZIO or (conteudo == TipoConteudo.MOEDA and quantidade_moedas <= 1):
		sprite.play("vazio") # Sprite marrom desativado
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	Global.adicionar_pontuacao(nome_jogador, 100)
	_criar_popup_pontos(100, global_position + Vector2(0, -16))
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicao_original + Vector2(0, -8), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", posicao_original, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _quebrar_bloco() -> void:
	ja_foi_atingido = true
	
	# Esconde o bloco e desativa a colisão imediatamente para o Mario passar direto por ele subindo
	sprite.hide()
	colisao.set_deferred("disabled", true)
	
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	Global.adicionar_pontuacao(nome_jogador, 100)
	_criar_popup_pontos(100, global_position + Vector2(0, -16))
	
	# Cria os 4 pedacinhos clássicos voando baseados em um Node2D
	if cena_pedaco_bloco:
		var posicoes = [
			Vector2(-2, -2), # Superior Esquerdo
			Vector2(2, -2),  # Superior Direito
			Vector2(-2, 2),  # Inferior Esquerdo
			Vector2(2, 2)    # Inferior Direito
		]
		
		var distancias_x = [-60, 60, -40, 40]
		var alturas_y = [-60, -60, -30, -30] # Pedaços superiores voam mais alto
		
		for i in range(4):
			var pedaco = cena_pedaco_bloco.instantiate() as Node2D
			if pedaco:
				# Posiciona cada pedacinho no seu respectivo canto
				pedaco.global_position = global_position + posicoes[i]
				get_parent().add_child(pedaco)
				
				# MÁGICA DOS TWEENS: Simula a física para o Node2D voar
				var tempo_subida = 0.25
				var tempo_queda = 0.4
				
				# 1. Movimento Horizontal Constante
				var tween_x = create_tween()
				tween_x.tween_property(pedaco, "global_position:x", pedaco.global_position.x + distancias_x[i], tempo_subida + tempo_queda)
				
				# 2. Movimento Vertical (Sobe perdendo força, desce ganhando força)
				var tween_y = create_tween()
				tween_y.tween_property(pedaco, "global_position:y", pedaco.global_position.y + alturas_y[i], tempo_subida).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween_y.tween_property(pedaco, "global_position:y", pedaco.global_position.y + 200, tempo_queda).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				
				# 3. Rotação do Pedacinho
				var tween_rot = create_tween()
				var giro = 720.0 if i % 2 == 1 else -720.0 # Direita gira horário, Esquerda anti-horário
				tween_rot.tween_property(pedaco, "rotation_degrees", giro, tempo_subida + tempo_queda)
				
				# Deleta o pedaço automaticamente quando terminar de cair
				tween_y.tween_callback(pedaco.queue_free)
	
	# Dá um tempinho e deleta o bloco invisível do mapa
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _liberar_item_da_cena() -> void:
	var cena_para_criar: PackedScene
	
	var jogador = get_tree().get_first_node_in_group("jogador")
	if jogador and jogador.estado_atual != JogadorSMB3.EstadoPoder.PEQUENO and conteudo == TipoConteudo.COGUMELO:
		conteudo = TipoConteudo.FOLHA_RACCOON
	
	match conteudo:
		TipoConteudo.MOEDA:
			cena_para_criar = cena_moeda_pulo
		TipoConteudo.COGUMELO:
			cena_para_criar = cena_cogumelo
		TipoConteudo.COGUMELO_VIDA:
			cena_para_criar = cena_cogumelo_vida
		TipoConteudo.FOLHA_RACCOON:
			cena_para_criar = cena_folha
	
	if cena_para_criar == null:
		return

	var item = cena_para_criar.instantiate()
	item.global_position = global_position
	item.z_index = -1 
	get_parent().add_child(item)

	if conteudo == TipoConteudo.MOEDA:
		_logica_moeda_pulo(item)
	else:
		_logica_item_subindo(item)

func _logica_moeda_pulo(moeda_instanciada: Node2D) -> void:
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	Global.adicionar_moeda(nome_jogador, 1)
	Global.adicionar_pontuacao(nome_jogador, 100)
	_criar_popup_pontos(100, global_position + Vector2(0, -16))
	
	var t = create_tween()
	t.tween_property(moeda_instanciada, "global_position:y", global_position.y - 40, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(moeda_instanciada, "global_position:y", global_position.y - 20, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(moeda_instanciada.queue_free)
	
	if quantidade_moedas > 1:
		quantidade_moedas -= 1
		sprite.play("cheio")
	else:
		ja_foi_atingido = true
		conteudo = TipoConteudo.VAZIO

func _logica_item_subindo(item_instanciado: Node2D) -> void:
	if item_instanciado.has_method("set_physics_process"):
		item_instanciado.set_physics_process(false)
	
	var t = create_tween()
	t.tween_property(item_instanciado, "global_position:y", global_position.y - 16, 0.5)
	t.tween_callback(func():
		item_instanciado.z_index = 0
		if item_instanciado.has_method("set_physics_process"):
			item_instanciado.set_physics_process(true)
		
		if item_instanciado.has_method("iniciar_movimento"):
			item_instanciado.iniciar_movimento()
	)
	
	ja_foi_atingido = true
	conteudo = TipoConteudo.VAZIO

func _criar_popup_pontos(valor: int, posicao: Vector2) -> void:
	if cena_pontuacao:
		var pontos = cena_pontuacao.instantiate()
		if pontos.has_node("Label"):
			pontos.get_node("Label").text = str(valor)
		pontos.global_position = posicao
		get_parent().add_child(pontos)


#class_name BlocoTijolo extends StaticBody2D
#
#const FRAGMENTO_CENA := preload("res://scenes/blocks/tijolo_fragmento.tscn")
#
#@onready var area_golpe: Area2D = $AreaGolpe
#
#var quebrado := false
#
#func _ready() -> void:
	#area_golpe.body_entered.connect(_on_golpe)
#
#func _on_golpe(body: Node2D) -> void:
	#if quebrado or not body is Mario:
		#return
	#hit_from_below(body)
#
#
#func hit_from_below(mario: Mario) -> void:
	#if quebrado:
		#return
	#if mario.state == Mario.MarioState.PEQUENO:
		#_sacudir()
	#elif mario.try_break_block():
		#_quebrar()
#
#
#func hit_by_tail(_source_position: Vector2) -> void:
	#if quebrado:
		#return
	#_quebrar()
#
#
#func hit_by_shell(_source_position: Vector2) -> void:
	#if quebrado:
		#return
	#_quebrar()
#
#func _sacudir() -> void:
	#var pos_original = position
	#var tween = create_tween()
	#tween.tween_property(self, "position", pos_original + Vector2(0, -4), 0.05)
	#tween.tween_property(self, "position", pos_original, 0.05)
#
#func _quebrar() -> void:
	#quebrado = true
	#_spawn_fragments()
	#queue_free()
#
#
#func _spawn_fragments() -> void:
	#for data in [
		#[Vector2(-4, -4), Vector2(-92, -250), -20.0],
		#[Vector2(4, -4), Vector2(92, -250), 20.0],
		#[Vector2(-4, 4), Vector2(-72, -170), -16.0],
		#[Vector2(4, 4), Vector2(72, -170), 16.0],
	#]:
		#var fragment := FRAGMENTO_CENA.instantiate()
		#fragment.global_position = global_position + data[0]
		#fragment.velocity = data[1]
		#fragment.spin_speed = data[2]
		#get_tree().current_scene.add_child(fragment)
