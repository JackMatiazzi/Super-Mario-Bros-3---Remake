extends StaticBody2D
class_name BlocoInterrogacao

enum TipoConteudo { MOEDA, COGUMELO, COGUMELO_VIDA, FOLHA_RACCOON }

@export var conteudo: TipoConteudo = TipoConteudo.MOEDA
@export var quantidade_moedas: int = 1

@export_category("Cenas dos Itens")
@export var cena_moeda_pulo: PackedScene   # A cena daquela moedinha que pula e some
@export var cena_cogumelo: PackedScene     # Tua cena do Super Cogumelo
@export var cena_cogumelo_vida: PackedScene     # Tua cena do Cogumelo verde
@export var cena_folha: PackedScene        # Tua cena da Folha Raccoon
@export var cena_pontuacao: PackedScene    # Tua cena de texto (100, 200, etc)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var ja_foi_atingido: bool = false
var posicao_original: Vector2

func _ready() -> void:
	posicao_original = global_position
	sprite.play("cheio")
	if not audio_player.playing:
		audio_player.play()

func bater_bloco(_eh_pequeno: bool) -> void:
	if ja_foi_atingido:
		return
	
	_executar_pulo_bloco()
	await get_tree().create_timer(0.2).timeout
	_liberar_item_da_cena()

func _executar_pulo_bloco() -> void:
	ja_foi_atingido = true
	sprite.play("vazio")
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	Global.adicionar_pontuacao(nome_jogador, 100)
	_criar_popup_pontos(100, global_position + Vector2(0, -16))
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicao_original + Vector2(0, -8), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", posicao_original, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _liberar_item_da_cena() -> void:
	var cena_para_criar: PackedScene
	
	var jogador = get_tree().get_first_node_in_group("jogador")
	if jogador and jogador.estado_atual != JogadorSMB3.EstadoPoder.PEQUENO and conteudo == TipoConteudo.COGUMELO:
		conteudo = TipoConteudo.FOLHA_RACCOON
	
	# Escolhe qual cena usar baseada no que tu configuraste no Inspetor
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
	# Coloca o item na mesma posição do bloco, mas um pouquinho atrás (Z-index)
	item.global_position = global_position
	item.z_index = -1 
	get_parent().add_child(item)

	# Lógica específica para cada tipo de item
	if conteudo == TipoConteudo.MOEDA:
		_logica_moeda_pulo(item)
	else:
		_logica_item_subindo(item)

func _logica_moeda_pulo(moeda_instanciada: Node2D) -> void:
	# Se a tua cena de moeda já tiver um script que faz ela pular sozinha,
	# tu podes apagar este código aqui embaixo.
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	Global.adicionar_moeda(nome_jogador, 1)
	Global.adicionar_pontuacao(nome_jogador, 100)
	_criar_popup_pontos(100, global_position + Vector2(0, -16))
	_tocar_audio("Coin")
	
	# Faz a moeda instanciada subir e sumir (estilo clássico)
	var t = create_tween()
	t.tween_property(moeda_instanciada, "global_position:y", global_position.y - 40, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(moeda_instanciada, "global_position:y", global_position.y - 20, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(moeda_instanciada.queue_free)
	
	# Se for bloco de múltiplas moedas, reseta
	if quantidade_moedas > 1:
		quantidade_moedas -= 1
		ja_foi_atingido = false
		sprite.play("idle")

func _logica_item_subindo(item_instanciado: Node2D) -> void:
	_tocar_audio("Powerup Appears")
	if item_instanciado.has_method("set_physics_process"):
		item_instanciado.set_physics_process(false)
	
	var t = create_tween()
	# Faz o item subir 16 pixels (o tamanho de um bloco) em 0.5 segundos
	t.tween_property(item_instanciado, "global_position:y", global_position.y - 16, 0.5)
	t.tween_callback(func():
		# Quando terminar de subir, ativamos o movimento e voltamos o Z-index ao normal
		item_instanciado.z_index = 0
		if item_instanciado.has_method("set_physics_process"):
			item_instanciado.set_physics_process(true)
		
		# Se for o Cogumelo, mandamos ele começar a andar para o lado certo
		if item_instanciado.has_method("iniciar_movimento"):
			item_instanciado.iniciar_movimento()
	)

func _criar_popup_pontos(valor: int, posicao: Vector2) -> void:
	if cena_pontuacao:
		var pontos = cena_pontuacao.instantiate()
		if pontos.has_node("Label"):
			pontos.get_node("Label").text = str(valor)
		pontos.global_position = posicao
		get_parent().add_child(pontos)
		
# ==========================================
# FUNÇÃO AUXILIAR PARA O ÁUDIO INTERATIVO
# ==========================================
func _tocar_audio(nome_clip: String) -> void:
	# Captura o controlador de reprodução interno (Playback)
	var playback = audio_player.get_stream_playback()
	
	# Troca para o clipe desejado pelo nome (certifique-se de que os nomes batem com os do editor)
	if playback:
		playback.switch_to_clip_by_name(nome_clip)

#class_name BlocoItem extends StaticBody2D
#
#enum ItemConteudo { NENHUM, COGUMELO, FOLHA, CUSTOM }
#
#const COGUMELO_SCENE = preload("res://scenes/items/cogumelo.tscn")
#const FOLHA_SCENE = preload("res://scenes/items/folha_super.tscn")
#
#@export var conteudo: ItemConteudo = ItemConteudo.COGUMELO
#@export var item_cena: PackedScene
#
#@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
#@onready var area_golpe: Area2D = $AreaGolpe
#
#var usado: bool = false
#
#func _ready() -> void:
	#area_golpe.body_entered.connect(_on_golpe)
	#sprite.play("cheio")
#
#func _on_golpe(body: Node2D) -> void:
	#if not body is Mario or usado:
		#return
	#hit_from_below(body)
#
#func _ativar() -> void:
	#usado = true
	#sprite.play("vazio")
	#_sacudir()
	#if _get_item_scene() != null:
		#call_deferred("_criar_item")
#
#
#func hit_from_below(_mario: Mario) -> void:
	#if not usado:
		#_ativar()
#
#
#func hit_by_tail(_source_position: Vector2) -> void:
	#if not usado:
		#_ativar()
#
#
#func hit_by_shell(_source_position: Vector2) -> void:
	#if not usado:
		#_ativar()
#
#
#func _criar_item() -> void:
	#var scene = _get_item_scene()
	#if scene == null:
		#return
	#var item = scene.instantiate()
	#get_parent().add_child(item)
	#item.global_position = global_position + Vector2(0, -16)
#
#
#func _get_item_scene():
	#match conteudo:
		#ItemConteudo.NENHUM:
			#return null
		#ItemConteudo.COGUMELO:
			#return COGUMELO_SCENE
		#ItemConteudo.FOLHA:
			#return FOLHA_SCENE
		#ItemConteudo.CUSTOM:
			#return item_cena
	#return null
#
#func _sacudir() -> void:
	#var pos_original = position
	#var tween = create_tween()
	#tween.tween_property(self, "position", pos_original + Vector2(0, -4), 0.05)
	#tween.tween_property(self, "position", pos_original, 0.05)
