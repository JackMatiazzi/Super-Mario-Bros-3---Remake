extends Marker2D
class_name MapPoint

@export var level: bool = false
@export var level_concluido: bool = false

@export_group("Conexões (Caminhos)")
@export_node_path("Marker2D") var acima
@export_node_path("Marker2D") var abaixo
@export_node_path("Marker2D") var esquerda
@export_node_path("Marker2D") var direita

@export_group("Status do Caminho")
# Por padrão deixamos TRUE. No Inspetor, se o caminho estiver trancado 
# (por um level ou porta), você vai lá e desmarca para FALSE.
@export var acima_liberado: bool = true
@export var abaixo_liberado: bool = true
@export var esquerda_liberado: bool = true
@export var direita_liberado: bool = true

# A função que você pediu: ela pega o que está FALSE e muda para TRUE,
# mas APENAS se você tiver configurado um NodePath válido ali!
func liberar_caminhos_da_fase() -> void:
	if not acima.is_empty() and not acima_liberado: 
		acima_liberado = true
	if not abaixo.is_empty() and not abaixo_liberado: 
		abaixo_liberado = true
	if not esquerda.is_empty() and not esquerda_liberado: 
		esquerda_liberado = true
	if not direita.is_empty() and not direita_liberado: 
		direita_liberado = true
	
	print("Caminhos deste ponto foram desbloqueados!")
