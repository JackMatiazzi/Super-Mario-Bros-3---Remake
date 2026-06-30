extends CharacterBody2D
class_name JogadorSMB3

# ==============================================================================
# SINAIS E ENUMS
# ==============================================================================
signal nivel_p_alterado(novo_nivel: int)

enum EstadoPoder { PEQUENO, SUPER, RACCOON }

# ==============================================================================
# CONFIGURAÇÕES DE FÍSICA FIÉIS AO SMB3
# ==============================================================================
@export_category("Física Clássica")
@export var VEL_CAMINHADA: float = 90.0
@export var VEL_CORRIDA: float = 150.0
@export var VEL_MAX_P_METER: float = 210.0 
@export var ACELERACAO: float = 280.0
@export var ATRITO: float = 400.0
@export var FORCA_DERRAPAGEM: float = 750.0 
@export var FORCA_PULO_BASE: float = -340.0
@export var FORCA_PULO_P_METER: float = -420.0 
@export var QUEDA_PLANADA_RACCOON: float = 60.0

@export_category("Sprites (.tres)")
@export var mario_pequeno: SpriteFrames
@export var mario_super: SpriteFrames
@export var mario_raccoon: SpriteFrames
@export var luigi_pequeno: SpriteFrames
@export var luigi_super: SpriteFrames
@export var luigi_raccoon: SpriteFrames

# ==============================================================================
# VARIÁVEIS DE CONTROLE INTERNO
# ==============================================================================
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var estado_atual: EstadoPoder = EstadoPoder.PEQUENO


# Timers de Animações e Habilidades Especiais
var tempo_chute: float = 0.0
var tempo_invencivel: float = 0.0
var tempo_voo_raccoon: float = 0.0 # Tempo restante para voar alto


# Mecânicas de Itens e Movimento
var carregando_item: bool = false
var nocauteado: bool = false
var derrapando: bool = false
var no_ar_p_meter: bool = false 
var girando_cauda: bool = false
var esta_voando: bool = false

# Controle do Medidor P (0.0 a 7.0)
var carga_p_meter: float = 0.0
var nivel_p_atual: int = 0

# Limites da Fase
var limite_esq: int = -10000000
var limite_dir: int = 10000000 
var limite_topo: int = -10000000
var limite_fundo: int = 10000000

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var detector_itens: Area2D = $DetectorItens
@onready var detector_colisao: CollisionShape2D = $DetectorItens/CollisionShape2D
@onready var area_cauda: Area2D = $AreaCauda
@onready var colisao_cauda: CollisionShape2D = $AreaCauda/CollisionShape2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# ==============================================================================
# CICLO PRINCIPAL
# ==============================================================================
func _ready() -> void:
	## Salva o jogador no script Global para itens e inimigos acharem ele facilmente
	#if Global.get("jogador_instancia") != null:
		#Global.jogador_instancia = self
	if not audio_player.playing:
		audio_player.play()
	
	_atualizar_visual_personagem()
	_ajustar_caixa_colisao()
	
	# Lê todos os limites na Camera2D (Adicionei verificação segura)
	var camera = get_viewport().get_camera_2d()
	if camera:
		limite_esq = camera.limit_left
		limite_dir = camera.limit_right
		limite_topo = camera.limit_top
		limite_fundo = camera.limit_bottom
	
	if detector_itens:
		detector_itens.body_entered.connect(_on_item_ou_casco_encostado)
		detector_itens.area_entered.connect(_on_item_ou_casco_encostado)
		
	if colisao_cauda:
		colisao_cauda.disabled = true
	if area_cauda:
		area_cauda.body_entered.connect(_on_area_cauda_body_entered)

func _physics_process(delta: float) -> void:
	if nocauteado:
		_processar_animacao_morte(delta)
		return
		
	var direcao := Input.get_axis("ui_left", "ui_right")
	var quer_correr := Input.is_action_pressed("run")
	
	# Ataque de cauda: Acionado apenas se não estiver carregando item
	if estado_atual == EstadoPoder.RACCOON and Input.is_action_just_pressed("run") and not girando_cauda and not carregando_item:
		_executar_ataque_cauda()

	_atualizar_timers(delta)
	_aplicar_gravidade_e_voo(delta)
	_tratar_pulo()
	_tratar_movimentacao_smb3(direcao, quer_correr, delta)
	_tratar_p_meter(quer_correr, delta)
	
	move_and_slide()
	
	_verificar_colisoes_teto()
	_gerenciar_animacoes(direcao)
	_verificar_limites_tela()

# ==============================================================================
# LÓGICA DE FÍSICA E MOVIMENTO CLÁSSICO
# ==============================================================================
func _aplicar_gravidade_e_voo(delta: float) -> void:
	if not is_on_floor():
		# Mecânica de Planar do Raccoon (apertar pulo repetidamente para cair devagar)
		if estado_atual == EstadoPoder.RACCOON and Input.is_action_just_pressed("jump") and velocity.y > 0:
			velocity.y = QUEDA_PLANADA_RACCOON
			if not girando_cauda:
				_tocar_animacao_rápida("tail")
		else:
			velocity.y += gravidade * delta
	else:
		no_ar_p_meter = false
		tempo_voo_raccoon = 0.0 # Reseta o tempo de voo livre ao tocar no chão

func _tratar_pulo() -> void:
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		_tocar_audio("Jump")
		if nivel_p_atual == 7:
			velocity.y = FORCA_PULO_P_METER
			no_ar_p_meter = true
			# Se estiver de Raccoon e pulou com a barra cheia, ganha 2.5s de voo livre!
			if estado_atual == EstadoPoder.RACCOON:
				tempo_voo_raccoon = 4.0
				esta_voando = true
		else:
			velocity.y = FORCA_PULO_BASE
			esta_voando = false
			
	# Voo Livre do Raccoon (Apertar pulo no ar com o tempo de voo ativo)
	elif not is_on_floor() and Input.is_action_just_pressed("jump") and estado_atual == EstadoPoder.RACCOON:
		if tempo_voo_raccoon > 0.0:
			velocity.y = FORCA_PULO_BASE * 0.9 # Voa para cima!
			_tocar_animacao_rápida("tail")

func _tratar_movimentacao_smb3(direcao: float, quer_correr: bool, delta: float) -> void:
	var vel_maxima = VEL_CAMINHADA
	if quer_correr:
		vel_maxima = VEL_MAX_P_METER if nivel_p_atual == 7 else VEL_CORRIDA

	derrapando = false

	if direcao != 0:
		if velocity.x != 0 and sign(direcao) != sign(velocity.x) and abs(velocity.x) > VEL_CAMINHADA:
			derrapando = true
			velocity.x = move_toward(velocity.x, 0, FORCA_DERRAPAGEM * delta)
		else:
			velocity.x = move_toward(velocity.x, direcao * vel_maxima, ACELERACAO * delta)
		
		if not derrapando and not girando_cauda:
			if direcao > 0:
				sprite.flip_h = true
			elif direcao < 0:
				sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, ATRITO * delta)

# ==============================================================================
# LÓGICA DO P-METER (SISTEMA DE CORRIDA)
# ==============================================================================
func _tratar_p_meter(quer_correr: bool, delta: float) -> void:
	var correndo_corretamente = is_on_floor() and quer_correr and abs(velocity.x) >= VEL_CORRIDA * 0.8
	
	if correndo_corretamente:
		carga_p_meter = move_toward(carga_p_meter, 7.0, delta * 8.0)
	else:
		carga_p_meter = move_toward(carga_p_meter, 0.0, delta * 5.0)
		
	var novo_nivel = floor(carga_p_meter)
	if novo_nivel != nivel_p_atual:
		nivel_p_atual = novo_nivel
		nivel_p_alterado.emit(nivel_p_atual)

# ==============================================================================
# MÁQUINA DE ANIMAÇÃO DO SMB3 
# ==============================================================================
func _gerenciar_animacoes(direcao: float) -> void:
	# Reseta a velocidade para o padrão
	sprite.speed_scale = 1.0
	
	if girando_cauda:
		return 

	if tempo_chute > 0.0:
		sprite.play("shoot")
		return

	if not is_on_floor():
		if no_ar_p_meter:
			sprite.play("run_jump")
		else:
			sprite.play("grab" if carregando_item else "jump")
		return

	if derrapando:
		sprite.play("slide")
	elif direcao != 0:
		if carregando_item:
			sprite.play("grab_walk")
			# Ajuste matemático seguro: começa de 1.0 e sobe dinamicamente até ~1.8
			sprite.speed_scale = 1.0 + (abs(velocity.x) / VEL_MAX_P_METER)
		
		elif nivel_p_atual == 7:
			sprite.play("run")
			# Começa de 1.5x mais rápido e acelera
			sprite.speed_scale = 1.5 + (abs(velocity.x) / VEL_MAX_P_METER)
			
		else:
			sprite.play("walk")
			# Quanto mais rápido anda, mais a perna gira
			sprite.speed_scale = 1.0 + (abs(velocity.x) / VEL_MAX_P_METER)
	else:
		sprite.play("grab" if carregando_item else "idle")

# Função auxiliar para quando o Raccoon voa ou plana forçando a cauda
func _tocar_animacao_rápida(nome_animacao: String) -> void:
	if sprite.sprite_frames.has_animation(nome_animacao):
		sprite.play(nome_animacao)

func _atualizar_timers(delta: float) -> void:
	tempo_chute = max(tempo_chute - delta, 0.0)
	tempo_invencivel = max(tempo_invencivel - delta, 0.0)
	tempo_voo_raccoon = max(tempo_voo_raccoon - delta, 0.0)
	
	if tempo_invencivel > 0.0:
		sprite.modulate.a = 0.5 if int(tempo_invencivel * 15) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

# ==============================================================================
# LIMITES DE TELA (CORRIGIDO PARA NÃO CRASHAR)
# ==============================================================================
func _verificar_limites_tela() -> void:
	var margem = 16.0
	
	global_position.x = clamp(global_position.x, limite_esq + margem, limite_dir - margem)
	
	if global_position.y < limite_topo + margem:
		global_position.y = limite_topo + margem
		velocity.y = 0 
		
	if global_position.y > limite_fundo:
		# Lógica de morte limpa
		_acionar_morte()

# ==============================================================================
# INTERAÇÃO: COMBATE, DANOS E ITENS
# ==============================================================================
func tomar_dano() -> void:
	if tempo_invencivel > 0.0 or nocauteado:
		return

	if estado_atual == EstadoPoder.PEQUENO:
		_acionar_morte()
	else:
		# Se for Super ou Raccoon, volta para Pequeno (SMB3 Original Rules)
		estado_atual = EstadoPoder.PEQUENO
		tempo_invencivel = 1.5
		_atualizar_visual_personagem()
		_ajustar_caixa_colisao()

func _acionar_morte() -> void:
	if nocauteado: return # Previne chamar 2 vezes
	_tocar_audio("Life Lost")
	nocauteado = true
	velocity = Vector2(0, -300.0)
	colisao.set_deferred("disabled", true)
	
	var eh_mario = Global.jogador_ativo == Global.Jogador.MARIO
	sprite.sprite_frames = mario_pequeno if eh_mario else luigi_pequeno
	sprite.play("die")

func _processar_animacao_morte(delta: float) -> void:
	velocity.y += gravidade * delta
	global_position += velocity * delta
	if global_position.y > limite_fundo + 100:
		var eh_mario = Global.jogador_ativo == Global.Jogador.MARIO
		if eh_mario:
			Global.vidas_mario -= 1
		else:
			Global.vidas_luigi -= 1
		# Volta para a cena do Mundo 1
		get_tree().change_scene_to_file("res://scenes/levels/mundo_1.tscn")

func chutar_objeto() -> void:
	tempo_chute = 0.25

func _on_item_ou_casco_encostado(objeto: Node2D) -> void:
	if objeto.has_method("ser_coletado"):
		objeto.ser_coletado(self)
	elif objeto.is_in_group("cascos"):
		if Input.is_action_pressed("run"):
			carregando_item = true
			objeto.ser_segurado(self)
		else:
			chutar_objeto()
			objeto.ser_chutado(global_position.x)

# ==============================================================================
# DETECÇÃO DE BLOCOS
# ==============================================================================
func _verificar_colisoes_teto() -> void:
	if is_on_ceiling():
		for i in get_slide_collision_count():
			var colisao_dados = get_slide_collision(i)
			if colisao_dados.get_normal().dot(Vector2.DOWN) > 0.8:
				var bloco = colisao_dados.get_collider()
				if bloco and bloco.has_method("bater_bloco"):
					bloco.bater_bloco(estado_atual == EstadoPoder.PEQUENO)

# ==============================================================================
# CARREGAMENTO DE ARQUIVOS E REDIMENSIONAMENTO (CORRIGIDO ALINHAMENTO DO CHÃO)
# ==============================================================================
func _atualizar_visual_personagem() -> void:
	var eh_mario: bool = Global.jogador_ativo == Global.Jogador.MARIO
	
	match estado_atual:
		EstadoPoder.PEQUENO:
			sprite.sprite_frames = mario_pequeno if eh_mario else luigi_pequeno
		EstadoPoder.SUPER:
			sprite.sprite_frames = mario_super if eh_mario else luigi_super
		EstadoPoder.RACCOON:
			sprite.sprite_frames = mario_raccoon if eh_mario else luigi_raccoon
	
	sprite.play("idle")

func _ajustar_caixa_colisao() -> void:
	var shape = colisao.shape as RectangleShape2D
	var detector_shape = detector_colisao.shape as RectangleShape2D
	if not shape: return
	
	if estado_atual == EstadoPoder.PEQUENO:
		shape.size = Vector2(12, 14)
		colisao.position = Vector2(0, 1) 
		detector_shape.size = Vector2(16, 16)
		detector_colisao.position = Vector2(0, 1)
	else:
		shape.size = Vector2(12, 26)
		colisao.position = Vector2(0, 1)
		detector_shape.size = Vector2(16, 28)
		detector_colisao.position = Vector2(0, 1)
		
# ==============================================================================
# LÓGICA DO ATAQUE DE CAUDA (RACCOON)
# ==============================================================================
func _executar_ataque_cauda() -> void:
	if not is_instance_valid(self): return
	girando_cauda = true
	
	var olhando_para_direita = sprite.flip_h
	
	if olhando_para_direita:
		area_cauda.position.x = 8
	else:
		area_cauda.position.x = -20 

	colisao_cauda.disabled = false
	if sprite.sprite_frames.has_animation("tail"):
		sprite.play("tail")
	
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self) or nocauteado: return # Segurança caso o jogador morra no meio do giro
	sprite.flip_h = !olhando_para_direita 
	
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self) or nocauteado: return
	sprite.flip_h = olhando_para_direita  
	
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(self) or nocauteado: return
	
	sprite.flip_h = olhando_para_direita
	colisao_cauda.disabled = true
	girando_cauda = false

func _on_area_cauda_body_entered(body: Node2D) -> void:
	# Segurança: a cauda não pode bater no próprio jogador
	if body != self and body.has_method("bater_bloco"):
		body.bater_bloco(false)
		_tocar_audio("Breakblock")

# ==========================================
# FUNÇÃO AUXILIAR PARA O ÁUDIO INTERATIVO
# ==========================================
func _tocar_audio(nome_clip: String) -> void:
	# Captura o controlador de reprodução interno (Playback)
	var playback = audio_player.get_stream_playback()
	
	# Troca para o clipe desejado pelo nome (certifique-se de que os nomes batem com os do editor)
	if playback:
		playback.switch_to_clip_by_name(nome_clip)
		
func _item_audio(tipo_item: String) -> void:
	if nocauteado: return
	
	match tipo_item:
		"moeda":
			_tocar_audio("Coin") 
		"cogumelo":
			_tocar_audio("Powerup")
		"folha_raccoon":
			_tocar_audio("Powerup")
		"goomba":
			_tocar_audio("Stomp")
