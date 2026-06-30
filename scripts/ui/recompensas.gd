extends AnimatedSprite2D
class_name RoletaFimFase

# Referência para a Area2D filha
@onready var area_colisao: Area2D = $Area2D

var ja_ativado: bool = false

func _ready() -> void:
	# Garante que a roleta comece piscando loucamente
	play("sorteio")

# Conecte o sinal 'body_entered' da sua Area2D aqui
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Só ativa se for o jogador e se ainda não foi pega
	if ja_ativado or not body.is_in_group("jogador"):
		return
		
	ja_ativado = true
	area_colisao.set_deferred("monitoring", false) # Desativa a área para não bugar
	
	# 1. Trava os comandos do jogador e faz ele fazer a pose de vitória/andar sozinho
	if body.has_method("mudar_estado_fim_fase"):
		body.mudar_estado_fim_fase()
	
	# 2. Captura qual era o frame atual da animação "sorteio"
	var frame_parado: int = frame
	var item_ganho: Global.TipoItem
	
	match frame_parado:
		0:
			item_ganho = Global.TipoItem.COGUMELO
			play("cogumelo")
		1:
			item_ganho = Global.TipoItem.FLOR
			play("flor")
		_:
			item_ganho = Global.TipoItem.ESTRELA
			play("estrela")
			
	# 3. Efeito Visual: A carta sobe flutuando e some (Igual ao SMB3)
	var tween = create_tween()
	tween.set_parallel(true) # Faz subir e sumir ao mesmo tempo
	tween.tween_property(self, "global_position:y", global_position.y - 64, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# 4. Avisa o script do Level que a fase acabou, passando o item coletado
	var level = get_tree().current_scene
	if level and level.has_method("concluir_fase"):
		level.concluir_fase(item_ganho)
