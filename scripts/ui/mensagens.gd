extends CanvasLayer

# Referenciando os filhos através do nó Control
@onready var painel_control = $Control
@onready var label_nome = $Control/Nome  # Ajuste para o nome exato do seu Label
@onready var label_vida = $Control/Vida  # Ajuste para o nome exato do seu Label
@onready var anim_sprite = $Control/Jogador

func _ready() -> void:
	# Começa com a mensagem escondida
	ocultar_mensagem()

# ESTA É A FUNÇÃO MÁGICA QUE VOCÊ VAI CHAMAR
func mostrar_mensagem(nome_jogador: String, vidas: int) -> void:
	# 1. Atualiza os textos dos Labels
	label_nome.text = nome_jogador
	label_vida.text = "%d" % vidas 

	# 2. Verifica quem é o jogador e toca a animação certa
	# (Lembre-se de deixar os nomes das animações em minúsculo no AnimatedSprite2D)
	if nome_jogador == "mario":
		anim_sprite.play(nome_jogador)
	elif nome_jogador == "luigi":
		anim_sprite.play(nome_jogador)
	
	# 3. Mostra todo o conjunto na tela
	painel_control.show()

func ocultar_mensagem() -> void:
	painel_control.hide()
	anim_sprite.stop()
