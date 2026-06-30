extends InimigoBase

func _comportamento_movimento(delta: float) -> void:
	super._comportamento_movimento(delta)
	# Inverte o flip do sprite com base na direção de caminhada
	sprite.flip_h = (direcao > 0)

func ser_esmagado(jogador: JogadorSMB3) -> void:
	super.ser_esmagado(jogador)
	
	# Desativa as colisões para não atrapalhar o cenário enquanto some
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# CORREÇÃO: Usando set_deferred para desativar de forma segura!
	detector_combate.set_deferred("monitoring", false)
	_criar_popup_pontos(100, global_position + Vector2(0, -16))
	
	if sprite.sprite_frames.has_animation("esmagado"):
		sprite.play("esmagado")
		
	# Espera o tempo do corpo achatado na tela antes de sumir por completo
	await get_tree().create_timer(0.3).timeout
	queue_free()
