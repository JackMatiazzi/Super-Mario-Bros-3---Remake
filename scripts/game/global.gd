extends Node

# Enum para sabermos quem está ativo
enum Jogador { MARIO, LUIGI }
# Enum global para os itens das cartas
enum TipoItem { NENHUM, COGUMELO, ESTRELA, FLOR }


# ==========================================
# 1. CONFIGURAÇÃO GERAL
# ==========================================
var quantidade_jogadores: int = 1 # Definido futuramente no menu (1 ou 2)
var jogador_ativo: Jogador = Jogador.LUIGI


# ==========================================
# 2. STATUS DO MARIO
# ==========================================
var vidas_mario: int = 5
var pontuacao_mario: int = 0
var moedas_mario: int = 0
var cartas_mario: Array[TipoItem] = [TipoItem.NENHUM, TipoItem.NENHUM, TipoItem.NENHUM]
var mario_eliminado: bool = false

# ==========================================
# 3. STATUS DO LUIGI
# ==========================================
var vidas_luigi: int = 5
var pontuacao_luigi: int = 0
var moedas_luigi: int = 0
var cartas_luigi: Array[TipoItem] = [TipoItem.NENHUM, TipoItem.NENHUM, TipoItem.NENHUM]
var luigi_eliminado: bool = false

# ==========================================
# 4. CONTROLE DO LEVEL (TEMPO)
# ==========================================
var tempo_restante: int = 300 # Contador regressivo do level atual

# ==========================================
# FUNÇÕES UTILIÁRIAS 
# ==========================================

# FUNÇÃO PARA ADICIONAR UMA CARTA NO ESPAÇO VAZIO
# Ela retorna o número do slot (0, 1 ou 2) onde a carta foi guardada!
func adicionar_carta(item: TipoItem) -> int:
	# Escolhe o inventário correto com base em quem está jogando
	var inventario = cartas_mario if jogador_ativo == Jogador.MARIO else cartas_luigi
	
	# Procura pelo primeiro espaço que seja NENHUM (vazio)
	for i in range(3):
		if inventario[i] == TipoItem.NENHUM:
			inventario[i] = item
			print("Carta guardada no slot ", i, " do jogador ativo!")
			return i # Retorna o índice do slot preenchido
			
	print("Inventário de cartas já está cheio!")
	return -1 # Retorna -1 se não houver espaço

# Manda essa função rodar sempre que um jogador pegar uma moeda na fase
func adicionar_moeda(jogador: String, quantidade: int = 1) -> void:
	if jogador == "mario":
		moedas_mario += quantidade
		if moedas_mario >= 100:
			moedas_mario -= 100
			vidas_mario += 1
			print("Mario ganhou uma vida extra por moedas!")
	
	elif jogador == "luigi":
		moedas_luigi += quantidade
		if moedas_luigi >= 100:
			moedas_luigi -= 100
			vidas_luigi += 1
			print("Luigi ganhou uma vida extra por moedas!")

# Manda essa função rodar sempre que o jogador derrotar inimigos ou pegar itens
func adicionar_pontuacao(jogador: String, pontos: int) -> void:
	if jogador == "mario":
		pontuacao_mario += pontos
	elif jogador == "luigi":
		pontuacao_luigi += pontos
		
# Manda essa função rodar sempre que o jogador pegar Cogumelo verde
func adicionar_vida(jogador: String, vida: int) -> void:
	if jogador == "mario":
		vidas_mario += vida
	elif jogador == "luigi":
		vidas_luigi += vida

# Chame isso no _ready() de cada fase para resetar o tempo padrão dela
func iniciar_tempo_da_fase(segundos: int) -> void:
	tempo_restante = segundos
	
# ==========================================
# FUNÇÃO: RESETAR O JOGO INTEIRO (VOLTAR AO PADRÃO)
# ==========================================
func resetar_jogo_total() -> void:
	quantidade_jogadores = 1
	jogador_ativo = Jogador.LUIGI
	
	mario_eliminado = false
	vidas_mario = 5
	pontuacao_mario = 0
	moedas_mario = 0
	cartas_mario = [TipoItem.NENHUM, TipoItem.NENHUM, TipoItem.NENHUM]
	
	luigi_eliminado = false
	vidas_luigi = 5
	pontuacao_luigi = 0
	moedas_luigi = 0
	cartas_luigi = [TipoItem.NENHUM, TipoItem.NENHUM, TipoItem.NENHUM]
	
	tempo_restante = 300
	print("Status global resetado para o padrão de início de jogo!")

# ==========================================
# FUNÇÃO: CONTROLAR FIM DE JOGO (VERIFICA VIDAS)
# ==========================================
func verificar_fim_de_jogo() -> void:
	# --- MODO DE 1 JOGADOR ---
	if quantidade_jogadores == 1:
		# Verifica quem é o jogador ativo e se as vidas dele acabaram
		if jogador_ativo == Jogador.MARIO and vidas_mario <= 0:
			mario_eliminado = true
			quantidade_jogadores = 0
		elif jogador_ativo == Jogador.LUIGI and vidas_luigi <= 0:
			luigi_eliminado = true
			quantidade_jogadores = 0

	# --- MODO DE 2 JOGADORES ---
	else:
		# Se o Mario morreu e ainda não tinha sido eliminado
		if vidas_mario <= 0 and not mario_eliminado:
			mario_eliminado = true
			print("Mario teve um Game Over individual!")
			quantidade_jogadores -= 1
			# Se o Luigi ainda estiver vivo, passa o controle para ele
			if not luigi_eliminado:
				jogador_ativo = Jogador.LUIGI
				
		# Se o Luigi morreu e ainda não tinha sido eliminado
		if vidas_luigi <= 0 and not luigi_eliminado:
			luigi_eliminado = true
			print("Luigi teve um Game Over individual!")
			quantidade_jogadores -= 1
			# Se o Mario ainda estiver vivo, passa o controle para ele
			if not mario_eliminado:
				jogador_ativo = Jogador.MARIO

	# --- CONDIÇÃO DE GAME OVER DEFINITIVO ---
	# Se a quantidade de jogadores ativos chegou a 0, limpa tudo e vai para o menu
	if quantidade_jogadores <= 0:
		print("GAME OVER DEFINITIVO! Voltando para o Menu Principal.")
		
		# Aguarda um pequeno frame para garantir consistência física antes de mudar de cena
		await get_tree().create_timer(1.0).timeout
		
		# Ajustado para o caminho correto do seu projeto
		get_tree().change_scene_to_file("res://scenes/ui/title_menu.tscn")
