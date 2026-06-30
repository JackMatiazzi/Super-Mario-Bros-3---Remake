extends Area2D
class_name MoedaCenario

@export var cena_pontuacao: PackedScene 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("default")

# ESSA FUNÇÃO É CHAMADA PELO JOGADOR QUANDO ELE ENCOSTA NA MOEDA
func ser_coletado(jogador: JogadorSMB3) -> void:
	# Desativa colisões para evitar dupla coleta no mesmo frame
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	jogador._item_audio("moeda")
	var nome_jogador = "mario" if Global.jogador_ativo == Global.Jogador.MARIO else "luigi"
	
	Global.adicionar_moeda(nome_jogador, 1)
	Global.adicionar_pontuacao(nome_jogador, 100)
		
	# CRIA O POPUP DE PONTOS
	_criar_popup_pontos(100, global_position)
	
	queue_free()

func _criar_popup_pontos(valor: int, posicao: Vector2) -> void:
	if cena_pontuacao:
		var pontos = cena_pontuacao.instantiate()
		if pontos is Label:
			pontos.text = str(valor)
		elif pontos.has_node("Label"):
			pontos.get_node("Label").text = str(valor)
			
		pontos.global_position = posicao
		get_parent().add_child(pontos)

#class_name Moeda extends Area2D
#
#var coletada := false
#
#func _ready() -> void:
	#body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body: Node2D) -> void:
	#if body is Mario and not coletada:
		#coletada = true
		#set_deferred("monitoring", false)
		#body.coletar_moeda(100)
		#queue_free()
