extends Camera2D

@export var jogador: CharacterBody2D

# A altura onde a câmera fica travada no chão
var altura_fixa_y: float = 0.0

# O PONTO DE DESTRAVE: Você pode ajustar isso no Inspetor.
# Quando o Y do jogador for MENOR que esse valor (subir muito), a câmera destrava.
@export var limite_para_subir: float = 0.0 

@export var velocidade_retorno_chao: float = 250.0

func _ready() -> void:
	altura_fixa_y = global_position.y
	if jogador:
		global_position.x = jogador.global_position.x
		reset_smoothing()

func _physics_process(delta: float) -> void:
	if not jogador:
		return
		
	# Sempre segue no eixo X
	global_position.x = jogador.global_position.x
	
	# A SUA LÓGICA DE TRAVAMENTO:
	if "esta_voando" in jogador and jogador.esta_voando:
		global_position.y = jogador.global_position.y
	# Como na Godot ir para cima diminui o valor de Y, verificamos se ele ficou menor que o limite
	if global_position.y < limite_para_subir:
		# Destrava na vertical e segue o jogador
		global_position.y = jogador.global_position.y
	else:
		# Trava na vertical e volta suavemente para a altura do chão
		global_position.y = move_toward(global_position.y, altura_fixa_y, velocidade_retorno_chao * delta)
