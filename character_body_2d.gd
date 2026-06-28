extends CharacterBody2D

const VELOCIDADE = 100.0
const FORCA_PULO = -300.0
const FORCA_VOO = -50.0

var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")
var esta_voando: bool = false
# Limites da Fase
var limite_esq: int = 0
var limite_dir: int = 10000 
var limite_topo: int = -10000
var limite_fundo: int = 10000

func _ready() -> void:
	# Lê todos os limites que você configurou na Camera2D
	var camera = get_viewport().get_camera_2d()
	if camera:
		limite_esq = camera.limit_left
		limite_dir = camera.limit_right
		limite_topo = camera.limit_top
		limite_fundo = camera.limit_bottom

func _physics_process(delta: float) -> void:
	# 1. GRAVIDADE
	if not is_on_floor() or not esta_voando:
		velocity.y += gravidade * delta
		esta_voando = false

	# 2. PULO
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = FORCA_PULO
		esta_voando = false

	# 3. VOO
	if Input.is_action_pressed("ui_up") and not is_on_floor():
		velocity.y = FORCA_VOO
		esta_voando = true

	# 4. MOVIMENTO
	var direcao = Input.get_axis("ui_left", "ui_right")
	if direcao:
		velocity.x = direcao * VELOCIDADE
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDADE)

	# 5. MOVE O PERSONAGEM
	move_and_slide()

	# ==========================================
	# 6. LIMITES DE TELA E MORTE
	# ==========================================
	var margem = 16.0
	
	# Trava nas paredes (Esquerda e Direita)
	global_position.x = clamp(global_position.x, limite_esq + margem, limite_dir - margem)
	
	# Trava no Teto (Impede de passar do limit_top)
	if global_position.y < limite_topo + margem:
		global_position.y = limite_topo + margem
		velocity.y = 0 # Faz ele "bater a cabeça" e perder o impulso de subida
		
	# Morte ao cair no buraco (Passou do limit_bottom)
	if global_position.y > limite_fundo:
		# Volta para a cena do Mundo 1
		get_tree().change_scene_to_file("res://mundo_1.tscn")
