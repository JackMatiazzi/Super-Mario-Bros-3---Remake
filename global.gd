extends Node

# Enum para sabermos quem está ativo
enum Jogador { MARIO, LUIGI }
# Enum global para os itens das cartas
enum TipoItem { NENHUM, COGUMELO, ESTRELA, FLOR }

# ==========================================
# 1. CONFIGURAÇÃO GERAL
# ==========================================
var quantidade_jogadores: int = 1 # Definido futuramente no menu (1 ou 2)
var jogador_ativo: Jogador = Jogador.MARIO

# ==========================================
# 2. STATUS DO MARIO
# ==========================================
var vidas_mario: int = 5
var pontuacao_mario: int = 0
var moedas_mario: int = 0
var cartas_mario: Array[TipoItem] = [TipoItem.NENHUM, TipoItem.NENHUM, TipoItem.NENHUM]

# ==========================================
# 3. STATUS DO LUIGI
# ==========================================
var vidas_luigi: int = 5
var pontuacao_luigi: int = 0
var moedas_luigi: int = 0
var cartas_luigi: Array[TipoItem] = [TipoItem.NENHUM, TipoItem.NENHUM, TipoItem.NENHUM]

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

# Chame isso no _ready() de cada fase para resetar o tempo padrão dela
func iniciar_tempo_da_fase(segundos: int) -> void:
	tempo_restante = segundos
